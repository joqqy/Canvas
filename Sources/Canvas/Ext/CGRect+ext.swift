//
//  CGRect+ext.swift
//  Canvas
//
//  Created by Chen on 2020/4/17.
//

import CoreGraphics

extension CGRect {
    
    public init(from p1: CGPoint, to p2: CGPoint) {
        let x = p1.x, y = p1.y
        let w = p2.x-x, h = p2.y-y
        self.init(x: x, y: y, width: w, height: h)
    }
    
}
