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
        let oldCtx = NSGraphicsContext.current
        
        #if os(OSX)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        #else
        UIGraphicsPushContext(ctx)
        #endif
        
        ctx.saveGState()
        block(ctx)
        ctx.restoreGState()
        
        #if os(OSX)
        NSGraphicsContext.current = oldCtx
        #else
        UIGraphicsPopContext()
        #endif
    }
    
}
