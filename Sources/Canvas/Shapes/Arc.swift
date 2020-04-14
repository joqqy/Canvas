//
//  Arc.swift
//  Canvas
//
//  Created by scchn on 2020/4/16.
//

import CoreGraphics

public func radiansToDegrees(_ r: CGFloat) -> CGFloat { r * 180 / .pi }

public func radiansForArc(_ vertex: CGPoint, _ pointA: CGPoint, _ pointB: CGPoint) -> CGFloat? {
    let len1 = Line(from: vertex, to: pointA).distance
    let len2 = Line(from: vertex, to: pointB).distance
    let len3 = Line(from: pointA, to: pointB).distance
    let a = (len1 * len1 + len2 * len2 - len3 * len3)
    let b = (len1 * len2 * 2.0)
    return b == 0 ? nil : acos(a / b)
}

public struct Arc {
    
    private static func reset(_ arc: Arc) -> Arc {
        let cr = CGFloat.pi * 2
        var arc = arc
        if arc.startAngle >= cr    { arc.startAngle -= cr }
        else if arc.startAngle < 0 { arc.startAngle += cr }
        else if arc.endAngle >= cr { arc.endAngle -= cr }
        else if arc.endAngle < 0   { arc.endAngle += cr }
        else                       { return arc }
        return reset(arc)
    }
    
    public var center: CGPoint
    
    public var radius: CGFloat
    
    public var startAngle: CGFloat
    
    public var endAngle: CGFloat
    
    public var clockwise: Bool
    
    public init(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        self.center     = center
        self.radius     = radius
        self.startAngle = startAngle
        self.endAngle   = endAngle
        self.clockwise  = clockwise
    }
    
    public init(center: CGPoint, point1: CGPoint, point2: CGPoint, radius: CGFloat) {
        let rab = Line(from: center, to: point1).radians
        let rac = Line(from: center, to: point2).radians
        self.center = center
        self.radius = radius
        startAngle = (rab >= 0 ? rab : 2 * .pi + rab)
        endAngle   = (rac >= 0 ? rac : 2 * .pi + rac)
        if startAngle > endAngle {
            swap(&startAngle, &endAngle)
        }
        clockwise = (endAngle - startAngle) > .pi
    }
    
    // 0~2pi
    public mutating func reset() {
        let cr = CGFloat.pi * 2
        if startAngle >= cr    { startAngle -= cr }
        else if startAngle < 0 { startAngle += cr }
        else if endAngle >= cr { endAngle -= cr }
        else if endAngle < 0   { endAngle += cr }
        else                   { return }
        reset()
    }
    
    private func _contains(_ point: CGPoint, d: CGFloat) -> Bool {
        let line = Line(from: center, to: point)
        if abs(line.distance - radius) < d {
            var lineAngle = line.radians
            let arc = Arc.reset(self)
            var start = min(arc.startAngle, arc.endAngle)
            var end = max(arc.startAngle, arc.endAngle)
            
            if abs(end - start) > .pi {
                end = end - .pi * 2
                if start > end { swap(&start, &end) }
            } else {
                if lineAngle < 0 { lineAngle += .pi * 2 }
            }
            
            return (start...end).contains(lineAngle)
        }
        return false
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        _contains(point, d: 0)
    }
    
    public func canSelect(by rect: CGRect) -> Bool {
        let corners = [CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                       CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY)]
        let sides = corners.enumerated().map { i, point -> Line in
            let j = (i+1) % corners.count
            return Line(from: point, to: corners[j])
        }
        for side in sides {
            let points = Circle(center: center, radius: radius).intersection(to: side)
            if points.contains(where: { side.contains($0) && _contains($0, d: 0.0001) }) {
                return true
            }
        }
        return false
    }
    
}
