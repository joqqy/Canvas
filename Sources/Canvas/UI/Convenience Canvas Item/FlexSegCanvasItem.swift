//
//  FlexSegCanvasItem.swift
//  Canvas
//
//  Created by scchn on 2020/4/21.
//

import CoreGraphics

open class FlexSegCanvasItem: CanvasItem, FixedElement {
    
    public let elements: Int
    
    open override var isCompleted: Bool { grid.last?.count == elements }
    
    /// The default value is 'false'
    open override var pushContinously: Bool { false }
    
    public init(elements: Int) {
        self.elements = elements
    }
    
    public required init() {
        fatalError("not implemented")
    }
    
    open override func push(_ point: CGPoint) {
        if let cnt = grid.last?.count, cnt < elements {
            super.push(point)
        } else {
            pushToNextSegment(point)
        }
    }
    
    open override func pushToNextSegment(_ point: CGPoint) {
        if grid.last == nil || isCompleted {
            super.pushToNextSegment(point)
        }
    }
    
}
