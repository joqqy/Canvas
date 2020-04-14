//
//  Circle.swift
//  Canvas
//
//  Created by scchn on 2020/4/16.
//

import CoreGraphics

public struct Circle {
    
    public var center: CGPoint
    
    public var radius: CGFloat
    
    public static var zero: Circle { Circle(center: .zero, radius: 0) }
    
    public init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
    
    public init?(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) {
        guard let (center, radius) = genCircle(a, b, c) else { return nil }
        self.center = center
        self.radius = radius
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        let l = Line(from: center, to: point)
        return l.dx*l.dx + l.dy*l.dy <= radius*radius
    }
    
    public func intersection(to line: Line) -> [CGPoint] {
        let baX = line.dst.x - line.src.x
        let baY = line.dst.y - line.src.y
        let caX = center.x - line.src.x
        let caY = center.y - line.src.y

        let a = baX * baX + baY * baY;
        let bBy2 = baX * caX + baY * caY;
        let c = caX * caX + caY * caY - radius * radius;
        
        let pBy2 = bBy2 / a;
        let q = c / a;
        
        let disc = pBy2 * pBy2 - q;
        if (disc < 0) {
            return []
        }
        
        let tmpSqrt = sqrt(disc);
        let abScalingFactor1 = -pBy2 + tmpSqrt;
        let abScalingFactor2 = -pBy2 - tmpSqrt;
        
        let p1 = CGPoint(x: line.src.x - baX * abScalingFactor1, y: line.src.y - baY * abScalingFactor1);
        if (disc == 0) {
            return [p1];
        }
        let p2 = CGPoint(x: line.src.x - baX * abScalingFactor2, y: line.src.y - baY * abScalingFactor2);
        return [p1, p2];
    }
    
    public func canSelect(by rect: CGRect) -> Bool {
        var dx = max(rect.maxX - center.x, center.x - rect.minX)
        var dy = max(rect.maxY - center.y, center.y - rect.minY)
        if !(dx * dx + dy * dy < radius * radius) {
            dx = center.x - max(rect.minX, min(center.x, rect.minX + rect.width))
            dy = center.y - max(rect.minY, min(center.y, rect.minY + rect.height))
            return dx * dx + dy * dy < radius * radius
        }
        return false
    }
    
}

// MARK: - genCircle

fileprivate func calcA(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
    return (p1.x * (p2.y - p3.y) - p1.y * (p2.x - p3.x) + p2.x * p3.y - p3.x * p2.y)
}

fileprivate func calcB(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat{
    let a = (p1.x * p1.x + p1.y * p1.y) * (p3.y - p2.y)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p1.y - p3.y)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p2.y - p1.y)
    return a + b + c
}

fileprivate func calcC(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat{
    let a = (p1.x * p1.x + p1.y * p1.y) * (p2.x - p3.x)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p3.x - p1.x)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p1.x - p2.x)
    return a + b + c
}

fileprivate func calcD(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
    let a = (p1.x * p1.x + p1.y * p1.y) * (p3.x * p2.y - p2.x * p3.y)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p1.x * p3.y - p3.x * p1.y)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p2.x * p1.y - p1.x * p2.y)
    return a + b + c
}

public func genCircle(_ point1: CGPoint, _ point2: CGPoint, _ point3: CGPoint) -> (center: CGPoint, radius: CGFloat)? {
    let a = calcA(point1, point2, point3)
    let b = calcB(point1, point2, point3)
    let c = calcC(point1, point2, point3)
    let d = calcD(point1, point2, point3)
    let center = CGPoint(x: -b / (2 * a), y: -c / (2 * a))
    let radius = sqrt((b * b + c * c - (4 * a * d)) / (4 * a * a))
    
    guard (!center.x.isNaN && !center.x.isInfinite) &&
            (!center.y.isNaN && !center.y.isInfinite) &&
            (!radius.isNaN && !radius.isInfinite) else
    {
        return nil
    }

    return (center, radius)
}
