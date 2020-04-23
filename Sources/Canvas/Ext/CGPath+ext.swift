//
//  CGPath+ext.swift
//  Canvas
//
//  Created by scchn on 2020/4/20.
//

import CoreGraphics

extension CGPath {
    
    static func box(center: CGPoint, width: CGFloat, rotation: CGFloat) -> CGPath {
        let corners = (0...3).reduce([CGPoint]()) { corners, i in
            let r = .pi / 4 + (.pi / 2 * CGFloat(i))
            let line = Line(from: center, radius: width / 2 * sqrt(2), angle: r + rotation)
            let corner = CGPoint(x: round(line.dst.x), y: round(line.dst.y))
            return corners + [corner]
        }
        let path = CGMutablePath()
        path.addLines(between: corners)
        path.closeSubpath()
        return path
    }
    
}

extension CGMutablePath {
    
    public static func circle(_ circle: Circle) -> CGMutablePath {
        let p = CGMutablePath()
        p.addCircle(circle)
        return p
    }
    
    public static func line(_ line: Line) -> CGMutablePath {
        let p = CGMutablePath()
        p.addLine(line)
        return p
    }
    
    public static func arc(_ arc: Arc) -> CGMutablePath {
        let p = CGMutablePath()
        p.addArc(arc)
        return p
    }
    
    public func addLine(_ line: Line) {
        addLines(between: [line.src, line.dst])
    }
    
    public func addLine(from point: CGPoint, length: CGFloat, angle: CGFloat) {
        move(to: point)
        addLine(to: point.extending(length: length, angle: angle))
    }
    
    public func addArc(_ arc: Arc) {
        move(to: arc.center.extending(length: arc.radius, angle: arc.startAngle))
        addArc(center: arc.center, radius: arc.radius, startAngle: arc.startAngle, endAngle: arc.endAngle, clockwise: arc.clockwise)
    }
    
    public func addCircle(_ circle: Circle) {
        addArc(center: circle.center, radius: circle.radius,
               startAngle: 0, endAngle: .pi*2,
               clockwise: true)
    }
    
}
