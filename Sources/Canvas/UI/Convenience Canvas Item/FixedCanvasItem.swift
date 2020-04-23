//
//  FixedCanvasItem.swift
//  Canvas
//
//  Created by scchn on 2020/4/21.
//

import CoreGraphics

open class FixedCanvasItem: CanvasItem, FixedElement, FixedSegment {
    
    public let segments: Int
    
    public let elements: Int
    
    open override var isCompleted: Bool { grid.count == segments && grid.last?.count == elements }
    
    /// The default value is 'false'
    open override var pushContinously: Bool { false }
    
    /// The default value is 'true'
    open override var finishWhenCompleted: Bool { true }
    
    public init(segments: Int, elements: Int) {
        self.segments = segments
        self.elements = elements
    }
    
    public required init() {
        fatalError("not implemented")
    }
    
    open override func push(_ point: CGPoint) {
        guard !isCompleted else { return }
        if let cnt = grid.last?.count, cnt < elements {
            super.push(point)
        } else if grid.count < segments {
            pushToNextSegment(point)
        }
    }
    
    open override func pushToNextSegment(_ point: CGPoint) {
        if grid.last == nil || grid.count < segments && grid.last?.count == elements {
            super.pushToNextSegment(point)
        }
    }
    
}
