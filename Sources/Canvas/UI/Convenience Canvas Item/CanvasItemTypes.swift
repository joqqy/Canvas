//
//  DrawerType.swift
//  Canvas
//
//  Created by Chen on 2020/4/22.
//

import Foundation

public protocol FixedElement: CanvasItem {
    var elements: Int { get }
}

public protocol FixedSegment: CanvasItem {
    var segments: Int { get }
}

public enum RotationAnchor {
    case onPoint(IndexPath)
    case flex(CGPoint)
}

public protocol Rotatable: CanvasItem {
    var rotationAngle: CGFloat { get set }
    var rotationAnchor: RotationAnchor { get set }
}
