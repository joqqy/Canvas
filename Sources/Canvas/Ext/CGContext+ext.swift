//
//  CGContext+ext.swift
//  Canvas
//
//  Created by Chen on 2020/4/16.
//

#if os(OSX)
import AppKit
#else
import UIKit
#endif

extension CGContext {
    
    public static func push(_ ctx: CGContext, using block: (CGContext) -> Void) {
        #if os(OSX)
        let oldCtx = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        block(ctx)
        NSGraphicsContext.current = oldCtx
        #else
        UIGraphicsPushContext(ctx)
        block(ctx)
        UIGraphicsPopContext()
        #endif
    }
    
}
