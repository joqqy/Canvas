//
//  CanvasBaseView.swift
//  Canvas
//
//  Created by scchn on 2020/4/16.
//

#if os(OSX)
import AppKit
#else
import UIKit
#endif

#if os(OSX)
@objcMembers
public class CanvasBaseView: NSView {
    
    var baseLayer: CALayer { layer! }
    
    // MARK: - Life Cycle
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    public override func layout() {
        super.layout()
        layout(baseLayer)
    }
    
    // MARK: - Mouse Event
    
    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        touchBegan(point)
    }
    
    public override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        touchDragged(point)
    }
    
    public override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        touchReleased(point)
    }
    
}
#else
@objcMembers
public class CanvasBaseView: UIView {
    
    var baseLayer: CALayer { layer }
    
    // MARK: - Life Cycle
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        layout(baseLayer)
    }
    
    // MARK: - Touch Event
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        touchBegan(point)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        touchDragged(point)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        touchReleased(point)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        touchReleased(point)
    }
    
}
#endif

extension CanvasBaseView {
    
    // must call super
    func commonInit() {
        #if os(OSX)
        layer = CALayer()
        wantsLayer = true
        #endif
    }
    
    // no-op
    func layout(_ layer: CALayer) {
    }
    
    // no-op
    func touchBegan(_ location: CGPoint) {}
    
    // no-op
    func touchDragged(_ location: CGPoint) {}
    
    // no-op
    func touchReleased(_ location: CGPoint) {}
    
}
