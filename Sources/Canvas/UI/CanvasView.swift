//
//  CanvasView.swift
//  Canvas
//
//  Created by Chen on 2020/4/15.
//

#if os(OSX)
import AppKit
#else
import UIKit
#endif

let MainScreenScale: CGFloat = {
    #if os(OSX)
    return NSScreen.main!.backingScaleFactor
    #else
    return UIScreen.main.scale
    #endif
}()

public protocol CanvasViewDelegate: AnyObject {
    func canvasView(_ canvasView: CanvasView, didFinish item: CanvasItem)
}

extension Notification.Name {
    public static let canvasViewDidEndSession = Notification.Name(rawValue: "scchn.canvasview.canvasViewDidEndSession")
    public static let canvasViewDidCancelSession = Notification.Name(rawValue: "scchn.canvasview.canvasViewDidCancelSession")
    public static let canvasViewDidDragItems = Notification.Name(rawValue: "scchn.canvasview.canvasViewDidDragItems")
    public static let canvasViewDidEditItem = Notification.Name(rawValue: "scchn.canvasview.canvasViewDidEditItem")
    public static let canvasViewDidChangeSelection = Notification.Name(rawValue: "scchn.canvasview.canvasViewDidChangeSelection")
}

extension CanvasView {
    
    enum State {
        case idle
        case selecting
        case drawing(CanvasItem)
        
        case onItem(CanvasItem, CGPoint)
        case dragging([CanvasItem], CGPoint, CGPoint)
        
        case onPoint(CanvasItem, IndexPath, CGPoint)
        case editing(CanvasItem, IndexPath, CGPoint)
    }
    
}

public class CanvasView: CanvasBaseView {
    
    public weak var delegate: CanvasViewDelegate?
    
    private var state: State = .idle
    
    private var itemLayerController: LayerController!
    
    private var rectLayerController: LayerController!
    
    private var selectionTool = SelectionTool()
    
    public private(set) var items: [CanvasItem] = []
    
    public var currnetItem: CanvasItem? {
        guard case .drawing(let item) = state else { return nil }
        return item
    }
    
    public var indicesOfSelectedItems: IndexSet {
        IndexSet(items.enumerated()
            .filter { _, item in item.isSelected }
            .map { idx, _ in idx })
    }
    
    // Settings
    
    private var zoomSize: CGSize = .zero
    
    public var shouldResizeItems = true
    
    public var rectBorderColor: Color {
        get { selectionTool.strokeColor }
        set {
            let oldValue = rectBorderColor
            selectionTool.strokeColor = newValue
            undoManager?.registerUndo(withTarget: self) { $0.rectBorderColor = oldValue }
        }
    }
    
    public var rectBackgroundColor: Color {
        get { selectionTool.fillColor }
        set {
            let oldValue = rectBackgroundColor
            selectionTool.fillColor = newValue
            undoManager?.registerUndo(withTarget: self) { $0.rectBackgroundColor = oldValue }
        }
    }
    
    public var strokeColor: Color = .black {
        didSet {
            undoManager?.registerUndo(withTarget: self) { $0.strokeColor = oldValue }
        }
    }
    
    public var fillColor: Color = .clear {
        didSet {
            undoManager?.registerUndo(withTarget: self) { $0.fillColor = oldValue }
        }
    }
    
    public var selectionRange: CGFloat = 7 {
        didSet {
            items.forEach { $0.selectionRadius = selectionRange }
            undoManager?.registerUndo(withTarget: self) { $0.selectionRange = oldValue }
        }
    }
    
    // MARK: - CanvasBaseView callbacks
    
    override func commonInit() {
        super.commonInit()
        
        // init item layer controller
        itemLayerController = LayerController()
        itemLayerController.frame = baseLayer.bounds
        itemLayerController.contentsScale = MainScreenScale
        baseLayer.addSublayer(itemLayerController.layer)
        
        // init rect layer controller
        selectionTool.layer.contentsScale = MainScreenScale
        selectionTool.layer.frame = baseLayer.bounds
        selectionTool.push(.zero)
        selectionTool.push(.zero)
        selectionTool.markAsFinished()
        baseLayer.addSublayer(selectionTool.layer)
    }
    
    private func scaleItem(_ item: CanvasItem, _ scaleX: CGFloat, _ scaleY: CGFloat) {
        item.beginBatchUpdate()
        for (i, points) in item.grid.enumerated() {
            for (j, point) in points.enumerated() {
                let newPoint = CGPoint(x: point.x * scaleX, y: point.y * scaleY)
                let indexPath = IndexPath(item: j, section: i)
                item.update(newPoint, at: indexPath)
            }
        }
        item.commitBatchUpdate()
    }
    
    private func scale(_ scaleX: CGFloat, _ scaleY: CGFloat) {
        for item in items {
            item.beginBatchUpdate()
            for (i, points) in item.grid.enumerated() {
                for (j, point) in points.enumerated() {
                    let newPoint = CGPoint(x: point.x * scaleX, y: point.y * scaleY)
                    let indexPath = IndexPath(item: j, section: i)
                    item.update(newPoint, at: indexPath)
                }
            }
            item.commitBatchUpdate()
        }
    }
    
    override func layout(_ layer: CALayer) {
        CATransaction.beginWithActionsDisabled {
            baseLayer.sublayers?.forEach {
                $0.frame = baseLayer.bounds
            }
        }
        
        let newSize = layer.frame.size
        if shouldResizeItems {
            let mx = newSize.width/zoomSize.width, my = newSize.height/zoomSize.height
            items.forEach { scaleItem($0, mx, my) }
        }
        zoomSize = layer.frame.size
    }
    
    private func postNot(name: Notification.Name, userInfo: [AnyHashable : Any]? = nil) {
        NotificationCenter.default.post(name: name, object: self, userInfo: userInfo)
    }
    
    // MARK: - Add/remove Items
    
    /// Add an item to the canvas.
    ///
    /// Once you add an item to `CanvasView`,
    /// the item will be marked as finished and will not able to push or pop anymore.
    public func addItem(_ item: CanvasItem) {
        if item.isCompleted {
            item.markAsFinished()
            item.undoManager = undoManager
            item.selectionRadius = selectionRange
            if !itemLayerController.contains(item.layer) {
                itemLayerController.addSublayer(item.layer)
            }
            items.append(item)
            regUndoForAddItem(item)
        }
    }
    
    public func removeItems(at indices: IndexSet) {
        var selectionChanged = false
        for i in indices.reversed() {
            let item = items.remove(at: i)
            item.layer.removeFromSuperlayer()
            regUndoForRemoveItem(item, zoomSize: zoomSize)
            if item.isSelected {
                selectionChanged = true
            }
        }
        if selectionChanged {
            postNot(name: .canvasViewDidChangeSelection)
        }
    }
    
    public func removeAllItems() {
        removeItems(at: IndexSet((0..<items.endIndex)))
    }
    
    // MARK: - Select/deselect Items
    
    private func selectItems(_ itemsToSelect: [CanvasItem]) {
        let oldSelection = Set(indicesOfSelectedItems)
        for item in items {
            if itemsToSelect.contains(item) {
                if !item.isSelected {
                    item.isSelected = true
                }
            } else if item.isSelected {
                item.isSelected = false
            }
        }
        
        if oldSelection != Set(indicesOfSelectedItems) {
            postNot(name: .canvasViewDidChangeSelection)
        }
    }
    
    public func selectItems(at indices: IndexSet) {
        selectItems(indices.map { items[$0] })
    }
    
    public func selectAllItems() {
        selectItems(at: IndexSet(0..<items.endIndex))
    }
    
    public func deselectItems(at indices: IndexSet) {
        selectItems(at: indicesOfSelectedItems.subtracting(indices))
    }
    
    public func deselectAllItems() {
        selectItems([])
    }
    
    // MARK: - Undo Reg Funcs
    
    private func regUndoForAddItem(_ item: CanvasItem) {
        undoManager?.registerUndo(withTarget: self, handler: { cv in
            if let idx = cv.items.firstIndex(of: item) {
                cv.removeItems(at: [idx])
            }
        })
    }
    
    private func regUndoForRemoveItem(_ item: CanvasItem, zoomSize: CGSize) {
        undoManager?.registerUndo(withTarget: self, handler: { cv in
            let mx = cv.zoomSize.width / zoomSize.width, my = cv.zoomSize.height / zoomSize.height
            cv.scaleItem(item, mx, my)
            cv.addItem(item)
        })
    }
    
    private func regUndoForDragging(items: [CanvasItem], offset: CGVector, zoomSize: CGSize) {
        undoManager?.registerUndo(withTarget: self, handler: { cv in
            let mx = cv.zoomSize.width / zoomSize.width, my = cv.zoomSize.height / zoomSize.height
            let t = CGAffineTransform(translationX: offset.dx * mx, y: offset.dy * my)
            items.forEach { $0.apply(t) }
            let redoOffset = CGVector(dx: -offset.dx, dy: -offset.dy)
            cv.regUndoForDragging(items: items, offset: redoOffset, zoomSize: zoomSize)
        })
    }
    
    private func regUndoForEditing(item: CanvasItem, offset: CGVector, at indexPath: IndexPath, zoomSize: CGSize) {
        undoManager?.registerUndo(withTarget: self, handler: { cv in
            let mx = cv.zoomSize.width / zoomSize.width, my = cv.zoomSize.height / zoomSize.height
            let t = CGAffineTransform(translationX: offset.dx * mx, y: offset.dy * my)
            item.apply(t, at: indexPath)
            let redoOffset = CGVector(dx: -offset.dx, dy: -offset.dy)
            cv.regUndoForEditing(item: item, offset: redoOffset, at: indexPath, zoomSize: zoomSize)
        })
    }
    
    // MARK: - Drawing Session
    
    public func beginDrawingSession(type: CanvasItem.Type) {
        endDrawingSession()
        
        let item = type.init()
        itemLayerController.addSublayer(item.layer)
        item.selectionRadius = selectionRange
        item.strokeColor = strokeColor
        item.fillColor = fillColor
        state = .drawing(item)
    }
    
    public func endDrawingSession() {
        if case let .drawing(item) = state {
            if item.isCompleted {
                addItem(item)
                state = .idle
                postNot(name: .canvasViewDidEndSession)
            } else {
                item.layer.removeFromSuperlayer()
                state = .idle
                postNot(name: .canvasViewDidCancelSession)
            }
        } else {
            selectItems([])
            state = .idle
        }
    }
    
    // MARK: - Touch Events
    
    private var reversedItemIndices: StrideThrough<Int> { stride(from: items.count - 1, through: 0, by: -1) }
    
    private func itemOnPoint(_ loc: CGPoint) -> CanvasItem? {
        if let i = reversedItemIndices.first(where: { items[$0].canSelect(by: loc) }) {
            return items[i]
        }
        return nil
    }
    
    private func itemsToDrag(at loc: CGPoint) -> [CanvasItem]? {
        for i in reversedItemIndices {
            let item = items[i]
            if item.canSelect(by: loc) {
                return !item.isSelected ? [item] : items.filter { $0.isSelected }
            }
        }
        return nil
    }
    
    private func itemToEdit(at loc: CGPoint) -> (CanvasItem, IndexPath)? {
        for i in reversedItemIndices {
            let item = items[i]
            if item.isSelected && !item.pushContinously {
                if let indexPath = item.indexOfPoint(at: loc) {
                    return (item, indexPath)
                }
            }
        }
        return nil
    }
    
    override func touchBegan(_ location: CGPoint) {
        switch state {
        case .idle:
            if let (item, indexPath) = itemToEdit(at: location) {
                selectItems([item])
                state = .onPoint(item, indexPath, location)
            } else if let item = itemOnPoint(location) {
                state = .onItem(item, location)
            } else {
                selectItems([])
                selectionTool.update(location, at: IndexPath(item: 0, section: 0))
                selectionTool.update(location, at: selectionTool.endIndexPath!)
                state = .selecting
            }
        case .drawing(let item):
            if item.pushContinously {
                item.pushToNextSegment(location)
            } else {
                if item.grid.last == nil {
                    item.push(location)
                } else if let item = item as? FixedElement, item.grid.last?.count == item.elements {
                    item.pushToNextSegment(location)
                }
                item.push(location)
            }
        default:
            break
        }
    }
    
    override func touchDragged(_ location: CGPoint) {
        switch state {
        case .selecting:
            selectionTool.update(location, at: selectionTool.endIndexPath!)
            selectItems(selectionTool.selectedItems(items))
        case .drawing(let item):
            if item.pushContinously {
                item.push(location)
            } else if let indexPath = item.endIndexPath {
                item.update(location, at: indexPath)
            }
        case .onItem(_, let startPoint):
            if let items = itemsToDrag(at: location) {
                selectItems(items)
                state = .dragging(items, startPoint, startPoint)
                touchDragged(location)
            }
        case .dragging(let items, let oldLoc, let startPoint):
            let t = CGAffineTransform(translationX: location.x - oldLoc.x, y: location.y - oldLoc.y)
            items.forEach { $0.apply(t) }
            state = .dragging(items, location, startPoint)
        case .onPoint(let item, let indexPath, let startPoint):
            state = .editing(item, indexPath, startPoint)
            touchDragged(location)
        case .editing(let item, let indexPath, _):
            item.update(location, at: indexPath)
        default:
            break
        }
    }
    
    override func touchReleased(_ location: CGPoint) {
        switch state {
        case .selecting:
            selectionTool.update(.zero, at: IndexPath(item: 0, section: 0))
            selectionTool.update(.zero, at: selectionTool.endIndexPath!)
            state = .idle
        case .drawing(let item):
            if item.isCompleted && item.finishWhenCompleted {
                endDrawingSession()
                delegate?.canvasView(self, didFinish: item)
            }
        case .onItem(let item, _):
            selectItems([item])
            state = .idle
        case .dragging(let items, _, let startPoint):
            let offset = CGVector(dx: startPoint.x - location.x, dy: startPoint.y - location.y)
            regUndoForDragging(items: items, offset: offset, zoomSize: zoomSize)
            state = .idle
            postNot(name: .canvasViewDidDragItems)
        case .onPoint:
            state = .idle
        case .editing(let item, let indexPath, let startPoint):
            let offset = CGVector(dx: startPoint.x - location.x, dy: startPoint.y - location.y)
            regUndoForEditing(item: item, offset: offset, at: indexPath, zoomSize: zoomSize)
            state = .idle
            postNot(name: .canvasViewDidEditItem)
        default:
            break
        }
    }
    
}
