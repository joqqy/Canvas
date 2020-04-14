//
//  PolylineItem.swift
//  Canvas
//
//  Created by Chen on 2020/4/17.
//

import Foundation
import CoreGraphics

public class PolylineItem: FlexEleCanvasItem, Distances {
    
    public private(set) var lines: [Line] = []
    
    public override var pushContinously: Bool { false }
    
    public required init() {
        super.init(segments: 1)
    }
    
    private func updateLines() {
        if isCompleted {
            lines = grid[0][..<(grid[0].endIndex - 1)]
                .enumerated()
                .map { Line(from: $1, to: grid[0][$0 + 1]) }
        }
    }
    
    public override func push(_ point: CGPoint) {
        super.push(point)
        updateLines()
    }
    
    public override func update(_ point: CGPoint, at indexPath: IndexPath) {
        super.update(point, at: indexPath)
        updateLines()
    }
    
    public override func canSelect(by rect: CGRect) -> Bool {
        lines.contains { $0.canSelect(by: rect) }
    }
    
}
