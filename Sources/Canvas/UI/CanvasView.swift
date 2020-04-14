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
    public static let canvasViewDidChangeSelection = Notification.Name(rawValue: "scchn.canvasview.canvasViewDidChangeSelection")
}

extension CanvasView {
    
    enum State {
        case idle
        case selecting
        case onItem(CanvasItem)
        case drawing(CanvasItem)
        case onPoint(CanvasItem, IndexPath)
        case editing(CanvasItem, IndexPath)
        case dragging(CGPoint)
    }
    
}

public class CanvasView: CanvasBaseView {
    
    public weak var delegate: CanvasViewDelegate?
    
    private var state: State = .idle
    
    private var size: CGSize = .zero
    
    private var itemLayerController: LayerController!
    
    private var rectLayerController: LayerController!
    
    private var selectionToolDrawer = RectSelectionItem()
    
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
    
    public var zoom = false
    
    public var rectBorderColor: Color {
        get { selectionToolDrawer.strokeColor }
        set { selectionToolDrawer.strokeColor = newValue }
    }
    
    public var rectBackgroundColor: Color {
        get { selectionToolDrawer.fillColor }
        set { selectionToolDrawer.fillColor = newValue }
    }
    
    public var selectionRange: CGFloat = 7 {
        didSet {
            items.forEach { $0.selectionRadius = selectionRange }
        }
    }
    
    private var customUndoManager: UndoManager?
    
    public func setUndoManager(_ undoManager: UndoManager) {
        customUndoManager = undoManager
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
        selectionToolDrawer.layer.contentsScale = MainScreenScale
        selectionToolDrawer.layer.frame = baseLayer.bounds
        selectionToolDrawer.push(.zero)
        selectionToolDrawer.push(.zero)
        selectionToolDrawer.markAsFinished()
        baseLayer.addSublayer(selectionToolDrawer.layer)
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
        if zoom {
            scale(newSize.width/size.width, newSize.height/size.height)
        }
        size = layer.frame.size
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
            itemLayerController.addSublayer(item.layer)
            items.append(item)
        }
    }
    
    public func removeItems(at indices: IndexSet) {
        var selectionChanged = false
        for i in indices.reversed() {
            let item = items.remove(at: i)
            item.layer.removeFromSuperlayer()
            undoManager?.removeAllActions(withTarget: item)
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
    
    // MARK: - Drawing Session
    
    public func beginDrawingSession(type: CanvasItem.Type) {
        endDrawingSession()
        
        let item = type.init()
        itemLayerController.addSublayer(item.layer)
        item.selectionRadius = selectionRange
        state = .drawing(item)
    }
    
    public func endDrawingSession() {
        if case let .drawing(item) = state {
            if item.isCompleted {
                item.markAsFinished()
                item.undoManager = undoManager
                items.append(item)
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
    
    private var revesedItemIndices: StrideThrough<Int> { stride(from: items.count - 1, through: 0, by: -1) }
    
    private func item(at loc: CGPoint) -> CanvasItem? {
        if let i = revesedItemIndices.first(where: { items[$0].canSelect(by: loc) }) {
            return items[i]
        }
        return nil
    }
    
    private func itemsToDrag(at loc: CGPoint) -> [CanvasItem]? {
        for i in revesedItemIndices {
            let item = items[i]
            if item.canSelect(by: loc) {
                return !item.isSelected ? [item] : items.filter { $0.isSelected }
            }
        }
        return nil
    }
    
    private func itemToEdit(at loc: CGPoint) -> (CanvasItem, IndexPath)? {
        for i in revesedItemIndices {
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
        case .drawing(let item):
            if item.pushContinously {
                item.pushToNextSegment(location)
            } else {
                if !item.isCompleted {
                    item.push(location)
                }
                item.push(location)
            }
        case .idle:
            if let (item, indexPath) = itemToEdit(at: location) {
                selectItems([item])
                state = .onPoint(item, indexPath)
            } else if let item = item(at: location) {
                state = .onItem(item)
            } else {
                selectItems([])
                selectionToolDrawer.update(location, at: IndexPath(item: 0, section: 0))
                selectionToolDrawer.update(location, at: selectionToolDrawer.endIndexPath!)
                state = .selecting
            }
        default:
            break
        }
    }
    
    override func touchDragged(_ location: CGPoint) {
        // Begin undo grouping
        switch state {
        case .onItem, .onPoint: undoManager?.beginUndoGrouping()
        default: break
        }
        
        switch state {
        case .drawing(let item):
            if item.pushContinously {
                item.push(location)
            } else if let indexPath = item.endIndexPath {
                item.update(location, at: indexPath)
            }
        case .selecting:
            selectionToolDrawer.update(location, at: selectionToolDrawer.endIndexPath!)
            selectItems(selectionToolDrawer.selectedItems(items))
        case .onPoint(let item, let indexPath):
            state = .editing(item, indexPath)
            touchDragged(location)
        case .editing(let item, let indexPath):
            item.update(location, at: indexPath)
        case .onItem:
            if let items = itemsToDrag(at: location) {
                selectItems(items)
                state = .dragging(location)
                touchDragged(location)
            }
        case .dragging(let oldLoc):
            let l = Line(from: oldLoc, to: location)
            let t = CGAffineTransform(translationX: l.dx, y: l.dy)
            indicesOfSelectedItems.forEach { items[$0].apply(t) }
            state = .dragging(location)
        default:
            break
        }
    }
    
    override func touchReleased(_ location: CGPoint) {
        // End current undo group
        switch state {
        case .dragging, .editing: undoManager?.endUndoGrouping()
        default: break
        }
        
        switch state {
        case .drawing(let item):
            if item.isCompleted && item.finishWhenCompleted {
                endDrawingSession()
                delegate?.canvasView(self, didFinish: item)
            }
        case .selecting:
            selectionToolDrawer.update(.zero, at: IndexPath(item: 0, section: 0))
            selectionToolDrawer.update(.zero, at: selectionToolDrawer.endIndexPath!)
            state = .idle
        case .onPoint:
            state = .idle
        case .editing:
            state = .idle
        case .onItem(let item):
            selectItems([item])
            state = .idle
        case .dragging:
            state = .idle
        default:
            break
        }
    }
    
}
