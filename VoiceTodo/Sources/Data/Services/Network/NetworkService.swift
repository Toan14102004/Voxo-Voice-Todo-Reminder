//
//  NetworkService.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 11/12/24.
//

import Alamofire
import Combine
import Foundation

class NetworkService {
    @Injected var localStorageService: LocalStorageService

    var baseURL: String {
        let remoteBaseURL = localStorageService.baseURL
        let defaultBaseURL = "https://api.example.com"
        let url = remoteBaseURL.isEmpty ? defaultBaseURL : remoteBaseURL
        // Remove trailing slash if present
        return url.hasSuffix("/") ? String(url.dropLast()) : url
    }

    let session: Session = {
        let configuration = URLSessionConfiguration.af.default

        let interceptor = AuthInterceptor()

        // Config time out
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true

        // Cache
        // Just using cache or config time out
        //        let responseCacher = ResponseCacher(behavior: .modify { _, response in
        //          let userInfo = ["date": Date()]
        //          return CachedURLResponse(
        //            response: response.response,
        //            data: response.data,
        //            userInfo: userInfo,
        //            storagePolicy: .allowed)
        //        })

        let networkLogger = GitNetworkLogger()
        return Session(
            configuration: configuration,
            interceptor: interceptor,
            //            cachedResponseHandler: responseCacher,
            eventMonitors: [networkLogger]
        )
    }()

    // MARK: - Generic Request Methods với Combine

    /// GET request
    func get<T: Codable>(
        endpoint: String,
        parameters: Parameters? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        request(
            endpoint: endpoint,
            method: .get,
            parameters: parameters,
            responseType: responseType
        )
    }

    /// POST request với JSON body
    func post<T: Codable>(
        endpoint: String,
        parameters: Parameters? = nil,
        body: Codable? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            body: body,
            responseType: responseType
        )
    }

    /// POST request với strongly typed body
    func post<T: Codable>(
        endpoint: String,
        body: some Codable,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        requestWithTypedBody(
            endpoint: endpoint,
            method: .post,
            body: body,
            responseType: responseType
        )
    }

    /// PUT request với JSON body
    func put<T: Codable>(
        endpoint: String,
        parameters: Parameters? = nil,
        body: Codable? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        request(
            endpoint: endpoint,
            method: .put,
            parameters: parameters,
            body: body,
            responseType: responseType
        )
    }

    /// PUT request với strongly typed body
    func put<T: Codable>(
        endpoint: String,
        body: some Codable,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        requestWithTypedBody(
            endpoint: endpoint,
            method: .put,
            body: body,
            responseType: responseType
        )
    }

    /// DELETE request
    func delete<T: Codable>(
        endpoint: String,
        parameters: Parameters? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        request(
            endpoint: endpoint,
            method: .delete,
            parameters: parameters,
            responseType: responseType
        )
    }

    // MARK: - Private Request Methods

    /// Request method với generic body (Codable)
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: Parameters? = nil,
        body: Codable? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        let url = baseURL + endpoint

        return Future<T, NetworkError> { promise in
            var request: DataRequest

            if let body {
                // Request với JSON body
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])

                    request = self.session.upload(jsonData, to: url, method: method, headers: [
                        "Content-Type": "application/json"
                    ])
                    .validate()
                    .responseData { response in
                        self.handleResponse(response: response, responseType: responseType, promise: promise)
                    }
                } catch {
                    promise(.failure(.encodingError(error)))
                    return
                }
            } else {
                // Request không có body
                request = self.session.request(
                    url,
                    method: method,
                    parameters: parameters,
                    encoding: method == .get ? URLEncoding.default : JSONEncoding.default
                )
                .validate()
                .responseData { response in
                    self.handleResponse(response: response, responseType: responseType, promise: promise)
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Request method với strongly typed body
    private func requestWithTypedBody<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: some Codable,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        let url = baseURL + endpoint

        return Future<T, NetworkError> { promise in
            do {
                let jsonData = try JSONEncoder().encode(body)

                let request = self.session.upload(jsonData, to: url, method: method, headers: [
                    "Content-Type": "application/json"
                ])
                .validate()
                .responseData { response in
                    self.handleResponse(response: response, responseType: responseType, promise: promise)
                }
            } catch {
                promise(.failure(.encodingError(error)))
            }
        }
        .eraseToAnyPublisher()
    }

    private func handleResponse<T: Codable>(
        response: AFDataResponse<Data>,
        responseType: T.Type,
        promise: @escaping (Result<T, NetworkError>) -> Void
    ) {
        switch response.result {
        case let .success(data):
            guard !data.isEmpty else {
                promise(.failure(.noData))
                return
            }

            do {
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }

                var cleanedData = stripBOM(from: data)
                if let responseString = String(data: cleanedData, encoding: .utf8) {
                    let cleanedString = cleanJsonResponse(responseString)
                    if cleanedString != responseString {
                        cleanedData = cleanedString.data(using: .utf8) ?? cleanedData
                    }
                }

                let decodedResponse = try JSONDecoder().decode(responseType, from: cleanedData)
                promise(.success(decodedResponse))
            } catch {
                promise(.failure(.decodingError(error)))
            }

        case let .failure(error):
            print("📥 Network Error: \(error)")
            if let statusCode = response.response?.statusCode {
                let errorMessage = response.data.flatMap { String(data: $0, encoding: .utf8) } ?? error
                    .localizedDescription
                promise(.failure(.serverError(statusCode, errorMessage)))
            } else {
                promise(.failure(.networkError(error)))
            }
        }
    }

    // MARK: - Helper Methods

    /// Removes UTF-8 BOM from data if present (fixes "isn't in the correct format" decoding errors).
    private func stripBOM(from data: Data) -> Data {
        let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
        guard data.count >= bom.count else { return data }
        if data.prefix(bom.count).elementsEqual(bom) {
            return data.dropFirst(bom.count)
        }
        return data
    }

    /// Cleans JSON response by removing markdown code block wrappers
    private func cleanJsonResponse(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove ```json at the beginning
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7)) // Remove "```json"
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3)) // Remove "```"
        }

        // Remove ``` at the end
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3)) // Remove "```"
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
