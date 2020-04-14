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
    
}
