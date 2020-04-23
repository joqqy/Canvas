//
//  LayerController.swift
//  Canvas
//
//  Created by Chen on 2020/4/15.
//

#if os(OSX)
import Quartz
#else
import QuartzCore
#endif

class LayerController: NSObject, CALayerDelegate {
    
    let layer: CALayer = CALayer()
    
    var sublayers: [CALayer] { layer.sublayers ?? [] }
    
    var contentsScale: CGFloat {
        get { layer.contentsScale }
        set { ([layer] + sublayers).forEach({ $0.contentsScale = newValue }) }
    }
    
    var frame: CGRect {
        get { layer.frame }
        set { layer.frame = newValue }
    }
    
    // Handlers
    var draw: ((CALayer, CGContext) -> Void)?
    var layerWillDraw: ((CALayer) -> Void)?
    var layoutSublayers: ((CALayer) -> Void)?
    var action: ((CALayer) -> CAAction)?
    
    override init() {
        super.init()
        layer.delegate = self
    }
    
    func addSublayer(_ sublayer: CALayer) {
        sublayer.frame = sublayer.bounds
        sublayer.contentsScale = contentsScale
        layer.addSublayer(sublayer)
    }
    
    func contains(_ layer: CALayer) -> Bool {
        layer.sublayers?.contains(layer) ?? false
    }
    
    // MARK: - CALayerDelegate
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        CATransaction.beginWithActionsDisabled {
            draw?(layer, ctx)
        }
    }
    
    func layerWillDraw(_ layer: CALayer) { layerWillDraw?(layer) }
    
    func action(for layer: CALayer, forKey event: String) -> CAAction? { action?(layer) }
    
    func layoutSublayers(of layer: CALayer) {
        CATransaction.beginWithActionsDisabled {
            layer.sublayers?.forEach {
                $0.frame = layer.bounds
                $0.setNeedsDisplay()
                $0.displayIfNeeded()
            }
            layoutSublayers?(layer)
        }
    }
    
}
