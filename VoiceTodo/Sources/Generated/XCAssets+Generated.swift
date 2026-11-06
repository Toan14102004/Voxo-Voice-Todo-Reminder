// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Assets {
    internal static let accentColor = ColorAsset(name: "AccentColor")
    internal static let appstore = ImageAsset(name: "appstore")
  }
  internal enum Color {
    internal static let bgBrandPrimary = ColorAsset(name: "bgBrandPrimary")
    internal static let bgBrandSecondary = ColorAsset(name: "bgBrandSecondary")
    internal static let bgBrandSolid = ColorAsset(name: "bgBrandSolid")
    internal static let bgErrorPrimary = ColorAsset(name: "bgErrorPrimary")
    internal static let bgErrorSecondary = ColorAsset(name: "bgErrorSecondary")
    internal static let bgErrorSolid = ColorAsset(name: "bgErrorSolid")
    internal static let bgOverlay = ColorAsset(name: "bgOverlay")
    internal static let bgPrimary = ColorAsset(name: "bgPrimary")
    internal static let bgPrimarySolid = ColorAsset(name: "bgPrimarySolid")
    internal static let bgSecondary = ColorAsset(name: "bgSecondary")
    internal static let bgSuccessPrimary = ColorAsset(name: "bgSuccessPrimary")
    internal static let bgSuccessSecondary = ColorAsset(name: "bgSuccessSecondary")
    internal static let bgSuccessSolid = ColorAsset(name: "bgSuccessSolid")
    internal static let bgTertiary = ColorAsset(name: "bgTertiary")
    internal static let bgPopup = ColorAsset(name: "bg_popup")
    internal static let black = ColorAsset(name: "black")
    internal static let borderBrand = ColorAsset(name: "borderBrand")
    internal static let borderDisable = ColorAsset(name: "borderDisable")
    internal static let borderError = ColorAsset(name: "borderError")
    internal static let borderPrimary = ColorAsset(name: "borderPrimary")
    internal static let borderSuccess = ColorAsset(name: "borderSuccess")
    internal static let colorBrand = ColorAsset(name: "colorBrand")
    internal static let fgBrandPrimary = ColorAsset(name: "fgBrandPrimary")
    internal static let fgBrandSecondary = ColorAsset(name: "fgBrandSecondary")
    internal static let fgErrorPrimary = ColorAsset(name: "fgErrorPrimary")
    internal static let fgErrorSecondary = ColorAsset(name: "fgErrorSecondary")
    internal static let fgPrimary = ColorAsset(name: "fgPrimary")
    internal static let fgSecondary = ColorAsset(name: "fgSecondary")
    internal static let fgSuccessPrimary = ColorAsset(name: "fgSuccessPrimary")
    internal static let fgSuccessSecondary = ColorAsset(name: "fgSuccessSecondary")
    internal static let fgTertiary = ColorAsset(name: "fgTertiary")
    internal static let fgWhite = ColorAsset(name: "fgWhite")
    internal static let gray = ColorAsset(name: "gray")
    internal static let grayText = ColorAsset(name: "gray_text")
    internal static let mainColor = ColorAsset(name: "mainColor")
    internal static let primary = ColorAsset(name: "primary")
    internal static let textBrandPrimary = ColorAsset(name: "textBrandPrimary")
    internal static let textBrandSecondary = ColorAsset(name: "textBrandSecondary")
    internal static let textDisable = ColorAsset(name: "textDisable")
    internal static let textErrorPrimary = ColorAsset(name: "textErrorPrimary")
    internal static let textPrimary = ColorAsset(name: "textPrimary")
    internal static let textSecondary = ColorAsset(name: "textSecondary")
    internal static let textSuccessPrimary = ColorAsset(name: "textSuccessPrimary")
    internal static let textTertiary = ColorAsset(name: "textTertiary")
    internal static let textWhite = ColorAsset(name: "textWhite")
    internal static let white = ColorAsset(name: "white")
  }
  internal enum Icon {
    internal enum Camera {
      internal enum Flash {
        internal static let flashOff = ImageAsset(name: "flashOff")
        internal static let flashOn = ImageAsset(name: "flashOn")
      }
      internal static let crosshair = ImageAsset(name: "crosshair")
    }
    internal enum Commo {
      internal static let arrowLeft = ImageAsset(name: "arrowLeft")
      internal static let arrowRateApp = ImageAsset(name: "arrowRateApp")
      internal static let checkPremium = ImageAsset(name: "checkPremium")
      internal static let checkmark = ImageAsset(name: "checkmark")
      internal static let checkmarkCircle = ImageAsset(name: "checkmarkCircle")
      internal static let circle = ImageAsset(name: "circle")
      internal static let icNoads = ImageAsset(name: "icNoads")
      internal static let locked = ImageAsset(name: "locked")
      internal static let plus = ImageAsset(name: "plus")
      internal static let premium = ImageAsset(name: "premium")
      internal static let saleTag = ImageAsset(name: "sale_tag")
      internal static let xmark = ImageAsset(name: "xmark")
    }
    internal enum Language {
      internal static let arabic = ImageAsset(name: "arabic")
      internal static let bengali = ImageAsset(name: "bengali")
      internal static let chinese = ImageAsset(name: "chinese")
      internal static let english = ImageAsset(name: "english")
      internal static let french = ImageAsset(name: "french")
      internal static let germany = ImageAsset(name: "germany")
      internal static let hindi = ImageAsset(name: "hindi")
      internal static let indonesian = ImageAsset(name: "indonesian")
      internal static let italian = ImageAsset(name: "italian")
      internal static let japanese = ImageAsset(name: "japanese")
      internal static let korea = ImageAsset(name: "korea")
      internal static let portuguese = ImageAsset(name: "portuguese")
      internal static let punjabi = ImageAsset(name: "punjabi")
      internal static let russian = ImageAsset(name: "russian")
      internal static let spanish = ImageAsset(name: "spanish")
      internal static let swahili = ImageAsset(name: "swahili")
    }
    internal enum Setting {
      internal static let contact = ImageAsset(name: "contact")
      internal static let happy = ImageAsset(name: "happy")
      internal static let language = ImageAsset(name: "language")
      internal static let premium = ImageAsset(name: "premium")
      internal static let sad = ImageAsset(name: "sad")
      internal static let share = ImageAsset(name: "share")
      internal static let shield = ImageAsset(name: "shield")
      internal static let star = ImageAsset(name: "star")
      internal static let starDisable = ImageAsset(name: "starDisable")
      internal static let starEnable = ImageAsset(name: "starEnable")
      internal static let thankFeedback = ImageAsset(name: "thankFeedback")
    }
  }
  internal enum Image {
    internal enum Premium {
      internal static let premiumBanner = ImageAsset(name: "premiumBanner")
      internal static let textOverlay = ImageAsset(name: "textOverlay")
    }
    internal enum Setting {
      internal static let imageBackground = ImageAsset(name: "imageBackground")
    }
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var uiColor: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal private(set) lazy var color: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var uiImage: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal var image: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
