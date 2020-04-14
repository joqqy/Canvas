//
//  PencilItem.swift
//  Canvas
//
//  Created by Chen on 2020/4/17.
//

import Foundation

public class PencilItem: FlexCanvasItem {
    
}

public class PencilItem2: FlexEleCanvasItem {
    
    public override var finishWhenCompleted: Bool { true }
    
    public required init() {
        super.init(segments: 1)
    }
    
}
