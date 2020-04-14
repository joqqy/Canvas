//
//  Line.swift
//  Canvas
//
//  Created by scchn on 2020/4/16.
//

import CoreGraphics

public struct Line {
    
    public enum IntersectionType {
        case intersection(CGPoint)
        case coline
        case parallel
    }
    
    public static var zero: Line { Line(from: .zero, to: .zero) }
    
    public var src: CGPoint
    
    public var dst: CGPoint
    
    public var dx: CGFloat { dst.x - src.x }
    
    public var dy: CGFloat { dst.y - src.y }
    
    public init(from src: CGPoint, to dst: CGPoint) { self.src = src; self.dst = dst }
    
    public init(from center: CGPoint, radius: CGFloat, angle: CGFloat) {
        src = center
        dst = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
    
    public var slope: CGFloat { dx/dy }
    
    public var vector: CGVector { CGVector(dx: dx, dy: dy) }
    
    public var mid: CGPoint { CGPoint(x: (src.x + dst.x) / 2.0, y: (src.y + dst.y) / 2.0) }
    
    public var radians: CGFloat { atan2(dy, dx) }
    
    public func radian(_ point: CGPoint) -> CGFloat? { 
        let len1 = Line(from: src, to: dst).distance
        let len2 = Line(from: src, to: point).distance
        let len3 = Line(from: dst, to: point).distance
        let a = (len1 * len1 + len2 * len2 - len3 * len3)
        let b = (len1 * len2 * 2.0)
        return b == 0 ? nil : acos(a / b)
    }
    
    public var distance: CGFloat { sqrt(dx*dx + dy*dy) }
    
    public func distance(_ point: CGPoint) -> CGFloat {
        let A = abs(dy * point.x - dx * point.y + dst.x * src.y - dst.y * src.x)
        let B = sqrt(dx * dx + dy * dy)
        return A / B
    }
    
    public func contains(_ pnt: CGPoint) -> Bool {
        let A = (src.x-pnt.x)*(src.x-pnt.x) + (src.y-pnt.y)*(src.y-pnt.y)
        let B = (dst.x-pnt.x)*(dst.x-pnt.x) + (dst.y-pnt.y)*(dst.y-pnt.y)
        let C = (src.x-dst.x)*(src.x-dst.x) + (src.y-dst.y)*(src.y-dst.y)
        return (A + B + 2 * sqrt(A * B) - C < 1)
    }
    
    public func intersection(_ line: Line) -> IntersectionType {
        let EPS: CGFloat = 1e-5
        func EQ(_ x: CGFloat, _ y: CGFloat) -> Bool { return abs(x - y) < EPS }
        let A1 = dst.y - src.y
        let B1 = src.x - dst.x
        let C1 = dst.x*src.y - src.x*dst.y
        let A2 = line.dst.y - line.src.y
        let B2 = line.src.x - line.dst.x
        let C2 = line.dst.x * line.src.y - line.src.x * line.dst.y
        if EQ(A1 * B2, B1 * A2) {
            return EQ( (A1 + B1) * C2, (A2 + B2) * C1 ) ? .coline : .parallel
        } else {
            let crossPoint = CGPoint(x: (B2 * C1 - B1 * C2) / (A2 * B1 - A1 * B2),
                                     y: (A1 * C2 - A2 * C1) / (A2 * B1 - A1 * B2))
            return .intersection(crossPoint)
        }
    }
    
    public func projection(_ point: CGPoint) -> CGPoint? {
        guard distance != 0 else { return nil }
        let A = src
        let B = dst
        let C = point
        let AC = CGPoint(x: C.x - A.x, y: C.y - A.y)
        let AB = CGPoint(x: B.x - A.x, y: B.y - A.y)
        let ACAB = AC.x * AB.x + AC.y * AB.y
        let m = ACAB / (distance * distance)
        let AD = CGPoint(x: AB.x * m, y: AB.y * m)
        let r = CGPoint(x: A.x + AD.x, y: A.y + AD.y)
        
        return r
    }

    
    // MARK: - ShapeType
    
    public func canSelect(by rect: CGRect) -> Bool {
        if rect.contains(src) || rect.contains(dst) {
            return true
        }
        let left   = lineLine(src.x, src.y, dst.x, dst.y, rect.minX           , rect.minY              , rect.minX              , rect.minY + rect.height);
        let right  = lineLine(src.x, src.y, dst.x, dst.y, rect.minX+rect.width, rect.minY              , rect.minX + rect.width , rect.minY + rect.height);
        let top    = lineLine(src.x, src.y, dst.x, dst.y, rect.minX           , rect.minY              , rect.minX + rect.width , rect.minY);
        let bottom = lineLine(src.x, src.y, dst.x, dst.y, rect.minX           , rect.minY + rect.height, rect.minX + rect.width , rect.minY + rect.height);
        return left || right || top || bottom
    }
    
    private func lineLine(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                          _ x3: CGFloat, _ y3: CGFloat, _ x4: CGFloat, _ y4: CGFloat) -> Bool
    {
        let uA = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
        let uB = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
        if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) { return true }
        return false;
    }
    
}
