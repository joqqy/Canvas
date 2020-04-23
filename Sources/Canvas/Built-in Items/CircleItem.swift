//
//  CircleItem.swift
//  Canvas
//
//  Created by Chen on 2020/4/20.
//

import CoreGraphics

public class CircleItem: FixedCanvasItem, Circular {
    
    public private(set) var circle: Circle = .zero
    
    public required init() {
        super.init(segments: 1, elements: 3)
    }
    
    public override func mainPathWrappers() -> [PathWrapper] {
        guard isCompleted else { return [] }
        let path = CGMutablePath()
        circle = Circle(grid[0][0], grid[0][1], grid[0][2]) ?? .zero
        path.addCircle(circle)
        return [PathWrapper(method: .stroke(lineWidth), color: strokeColor, path: path)]
    }
    
    public override func canSelect(by rect: CGRect) -> Bool {
        circle.canSelect(by: rect)
    }
    
}
