//
//  FlexEleCanvasItem.swift
//  Canvas
//
//  Created by scchn on 2020/4/21.
//

import CoreGraphics

open class FlexEleCanvasItem: CanvasItem, FixedSegment {
    
    public let segments: Int
    
    open override var isCompleted: Bool { grid.last?.isEmpty == false }
    
    public init(segments: Int) {
        self.segments = segments
    }
    
    public required init() {
        fatalError("not implmeneted")
    }
    
    open override func pushToNextSegment(_ point: CGPoint) {
        if isCompleted {
            super.pushToNextSegment(point)
        }
    }
    
}
