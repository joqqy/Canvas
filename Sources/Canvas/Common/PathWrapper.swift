//
//  PathWrapper.swift
//  Canvas
//
//  Created by Chen on 2020/4/21.
//

import CoreGraphics

public class PathWrapper {

    public enum DrawingMethod {
        case stroke(CGFloat)
        case dash(CGFloat, CGFloat, [CGFloat])
        case fill
    }
    
    public var color: Color
    public var method: DrawingMethod
    public var path: CGPath
    
    public init(method: DrawingMethod, color: Color, path: CGPath) {
        self.color = color
        self.method = method
        self.path = path
    }
    
    private func applyMethod(_ method: DrawingMethod, in ctx: CGContext) {
        switch method {
        case .dash(let w, let p, let l):
            ctx.setLineDash(phase: p, lengths: l)
            fallthrough
        case .stroke(let w):
            ctx.setLineWidth(w)
            ctx.setStrokeColor(color.cgColor)
        case .fill:
            ctx.setFillColor(color.cgColor)
        }
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
    }
    
    private func drawPath(_ path: CGPath, in ctx: CGContext) {
        ctx.addPath(path)
        if case .fill = method {
            ctx.fillPath()
        } else {
            ctx.strokePath()
        }
    }
    
    public func draw(in ctx: CGContext) {
        ctx.saveGState()
        applyMethod(method, in: ctx)
        drawPath(path, in: ctx)
        ctx.restoreGState()
    }
    
}

extension Array where Element == PathWrapper {
    func drawPaths(in ctx: CGContext) { forEach { $0.draw(in: ctx) } }
}
