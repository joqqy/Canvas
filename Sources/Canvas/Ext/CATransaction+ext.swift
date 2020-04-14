//
//  CATransaction+ext.swift
//  Canvas
//
//  Created by Chen on 2020/4/16.
//

#if os(OSX)
import Quartz
#else
import QuartzCore
#endif

extension CATransaction {
    
    public static func beginWithActionsDisabled(_ block: () -> Void) {
        CATransaction.begin()
        defer { CATransaction.commit() }
        CATransaction.setDisableActions(true)
        block()
    }
    
}
