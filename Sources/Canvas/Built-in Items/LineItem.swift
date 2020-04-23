//
//  LineItem.swift
//  Canvas
//
//  Created by Chen on 2020/4/20.
//

import CoreGraphics

public class LineItem: FixedCanvasItem, Distances {
    
    public private(set) var lines: [Line] = []
    
    public required init() {
        super.init(segments: 1, elements: 2)
    }
    
    public override func mainPathWrappers() -> [PathWrapper] {
        guard isCompleted else { return [] }
        lines = [Line(from: grid[0][0], to: grid[0][1])]
        return super.mainPathWrappers()
    }
    
    public override func canSelect(by rect: CGRect) -> Bool {
        if let line = lines.first {
            return line.canSelect(by: rect)
        }
        return false
    }
    
}
