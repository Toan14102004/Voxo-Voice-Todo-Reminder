//
//  CameraView+Grid.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import SwiftUI
import UIKit

class CameraGridView: UIView {
    var parent: CameraManager!
}

// MARK: Setup

extension CameraGridView {
    func setup(parent: CameraManager) {
        self.parent = parent
        alpha = parent.attributes.grid != .off ? 1 : 0
        addToParent(parent.cameraView)
    }
}

// MARK: Set Visibility

extension CameraGridView {
    func setVisibility(_ isVisible: Bool) {
        UIView.animate(withDuration: 0.2) { self.alpha = isVisible ? 1 : 0 }
        parent.attributes.isGridVisible = isVisible
    }

    func setGrid(_ grid: Grid) {
        let isVisible = grid != .off
        UIView.animate(withDuration: 0.2) { self.alpha = isVisible ? 1 : 0 }
        parent.attributes.grid = grid
        setNeedsDisplay()
    }
}

// MARK: Draw

extension CameraGridView {
    override func draw(_: CGRect) {
        clearOldLayersBeforeDraw()

        guard parent.attributes.grid != .off else { return }

        switch parent.attributes.grid {
        case .off:
            break
        case .threeByThree:
            drawThreeByThreeGrid()
        case .fourByFour:
            drawFourByFourGrid()
        }
    }

    private func drawThreeByThreeGrid() {
        // Vertical lines
        let firstColumnPath = UIBezierPath()
        firstColumnPath.move(to: CGPoint(x: bounds.width / 3, y: 0))
        firstColumnPath.addLine(to: CGPoint(x: bounds.width / 3, y: bounds.height))
        let firstColumnLayer = createGridLayer()
        firstColumnLayer.path = firstColumnPath.cgPath
        layer.addSublayer(firstColumnLayer)

        let secondColumnPath = UIBezierPath()
        secondColumnPath.move(to: CGPoint(x: (2 * bounds.width) / 3, y: 0))
        secondColumnPath.addLine(to: CGPoint(x: (2 * bounds.width) / 3, y: bounds.height))
        let secondColumnLayer = createGridLayer()
        secondColumnLayer.path = secondColumnPath.cgPath
        layer.addSublayer(secondColumnLayer)

        // Horizontal lines
        let firstRowPath = UIBezierPath()
        firstRowPath.move(to: CGPoint(x: 0, y: bounds.height / 3))
        firstRowPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height / 3))
        let firstRowLayer = createGridLayer()
        firstRowLayer.path = firstRowPath.cgPath
        layer.addSublayer(firstRowLayer)

        let secondRowPath = UIBezierPath()
        secondRowPath.move(to: CGPoint(x: 0, y: (2 * bounds.height) / 3))
        secondRowPath.addLine(to: CGPoint(x: bounds.width, y: (2 * bounds.height) / 3))
        let secondRowLayer = createGridLayer()
        secondRowLayer.path = secondRowPath.cgPath
        layer.addSublayer(secondRowLayer)
    }

    private func drawFourByFourGrid() {
        // Vertical lines
        for i in 1...3 {
            let x = (CGFloat(i) * bounds.width) / 4
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: bounds.height))
            let layer = createGridLayer()
            layer.path = path.cgPath
            self.layer.addSublayer(layer)
        }

        // Horizontal lines
        for i in 1...3 {
            let y = (CGFloat(i) * bounds.height) / 4
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.width, y: y))
            let layer = createGridLayer()
            layer.path = path.cgPath
            self.layer.addSublayer(layer)
        }
    }
}

private extension CameraGridView {
    func clearOldLayersBeforeDraw() {
        layer.sublayers?.removeAll()
        layer.backgroundColor = .none
    }

    func createGridLayer() -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        shapeLayer.frame = bounds
        shapeLayer.fillColor = nil
        return shapeLayer
    }
}
