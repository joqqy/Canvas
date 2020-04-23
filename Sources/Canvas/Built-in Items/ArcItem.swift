//
//  ArcItem.swift
//  Canvas
//
//  Created by Chen on 2020/4/21.
//

import CoreGraphics

public class ArcItem: FixedCanvasItem, Angular {
    
    public private(set) var arc: Arc?
    
    public private(set) var angles: [CGFloat] = []
    
    public required init() {
        super.init(segments: 1, elements: 3)
    }
    
    private func updateArc() {
        if let angle = radiansForArc(grid[0][1], grid[0][0], grid[0][2]) {
            let line1 = Line(from: grid[0][1], to: grid[0][0])
            let line2 = Line(from: grid[0][1], to: grid[0][2])
            let radius = max(line1.distance, line2.distance)
            
            arc = Arc(center: grid[0][1], point1: grid[0][0], point2: grid[0][2], radius: radius)
            angles = [angle]
        } else {
            arc = nil
            angles = []
        }
    }
    
    public override func mainPathWrappers() -> [PathWrapper] {
        guard isCompleted else { return [] }
        updateArc()
        guard let arc = arc else { return [] }
        let mainPath = CGMutablePath()
        mainPath.addLine(from: arc.center, length: arc.radius, angle: arc.startAngle)
        mainPath.addLine(from: arc.center, length: arc.radius, angle: arc.endAngle)
        mainPath.addArc(arc)
        
        let vertexPath = CGMutablePath()
        var vertex = arc
        vertex.radius = arcRadiusOfVertex
        vertexPath.addArc(vertex)
        
        return [
            PathWrapper(method: .stroke(lineWidth), color: strokeColor, path: mainPath),
            PathWrapper(method: .dash(lineWidth, 1, [4, 4]), color: strokeColor, path: vertexPath)]
    }
    
    public override func canSelect(by rect: CGRect) -> Bool {
        guard let arc = arc else { return false }
        let points = [
            arc.center.extending(length: arc.radius, angle: arc.startAngle),
            arc.center.extending(length: arc.radius, angle: arc.endAngle)]
        let lines = points.map { Line(from: arc.center, to: $0)}
        return lines.contains { $0.canSelect(by: rect) } || arc.canSelect(by: rect)
    }
    
}
