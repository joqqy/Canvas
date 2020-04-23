//
//  CGPoint+ext.swift
//  Canvas
//
//  Created by Chen on 2020/4/22.
//

import CoreGraphics

extension CGPoint {
    
    public func extending(length: CGFloat, angle: CGFloat = 0) -> CGPoint {
        CGPoint(x: x + length * cos(angle), y: y + length * sin(angle))
    }
    
    public mutating func extend(length: CGFloat, angle: CGFloat = 0) {
        self = extending(length: length, angle: angle)
    }
    
    public func rotating(origin: CGPoint, angle: CGFloat) -> CGPoint {
        let transform = CGAffineTransform.identity.translatedBy(x: origin.x, y: origin.y).rotated(by: angle)
        return CGPoint(x: x - origin.x, y: y - origin.y).applying(transform)
    }
    
    public mutating func rotate(origin: CGPoint, angle: CGFloat) {
        self = rotating(origin: origin, angle: angle)
    }
    
}
