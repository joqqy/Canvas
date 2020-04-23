//
//  CanvasItem.swift
//  Canvas
//
//  Created by Chen on 2020/4/15.
//

#if os(OSX)
import AppKit
#else
import UIKit
#endif

open class CanvasItem: Hashable {
    
    public static func == (lhs: CanvasItem, rhs: CanvasItem) -> Bool { lhs === rhs }
    
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    // MARK: - Private
    
    private var stack = Stack()
    
    private var id = UUID()
    
    private let layerController: LayerController = LayerController()
    
    private var _mainPathWrappers: [PathWrapper] = []
    
    private var _selectedPathWrappers: [PathWrapper] = []
    
    private var batchUpdating = false
    
    // MARK: - Internal
    
    var layer: CALayer { layerController.layer }
    
    var undoManager: UndoManager?
    
    // MARK: - Read only
    
    open var grid: [[CGPoint]] { stack.grid }
    
    open private(set) var transform: CGAffineTransform = .identity
    
    open var isCompleted: Bool { stack.endIndexPath != nil }
    
    open var endIndexPath: IndexPath? { stack.endIndexPath }
    
    open private(set) var isFinished = false {
        didSet { if isFinished != oldValue { redraw() } }
    }
    
    open internal(set) var isSelected = false {
        didSet { if isSelected != oldValue { redraw() } }
    }
    
    /// The default value is 'true'
    open var pushContinously: Bool { true }
    
    /// The default value is 'false'
    open var finishWhenCompleted: Bool { false }
    
    // MARK: - Read/Write
    
    open var strokeColor: Color = .black {
        didSet {
            redraw()
            undoManager?.registerUndo(withTarget: self) { $0.strokeColor = oldValue }
        }
    }
    
    open var fillColor: Color = .black {
        didSet {
            redraw()
            undoManager?.registerUndo(withTarget: self) { $0.fillColor = oldValue }
        }
    }
    
    open var lineWidth: CGFloat = 1 {
        didSet {
            redraw()
            undoManager?.registerUndo(withTarget: self) { $0.lineWidth = oldValue }
        }
    }
    
    open var isHidden: Bool {
        get { layer.isHidden }
        set {
            let o = layer.isHidden
            layer.isHidden = newValue
            undoManager?.registerUndo(withTarget: self) { $0.isHidden = o }
        }
    }
    
    open var selectionRadius: CGFloat = 7 {
        didSet {
            undoManager?.registerUndo(withTarget: self) { $0.selectionRadius = oldValue }
        }
    }
    
    // MARK: - Life Cycle
    
    required public init() {
        layerController.draw = { [weak self] layer, ctx in
            self?.draw(in: ctx)
        }
    }
    
    // MARK: - Edit
    
    open func beginBatchUpdate() {
        batchUpdating = true
    }
    
    open func commitBatchUpdate() {
        batchUpdating = false
        redraw()
    }
    
    open func push(_ point: CGPoint) {
        if !isFinished {
            stack.push(point)
            redraw()
        }
    }
    
    open func pushToNextSegment(_ point: CGPoint) {
        if !isFinished {
            stack.pushToNext(point)
            redraw()
        }
    }
    
    @discardableResult
    func pop() -> CGPoint? {
        guard !isFinished, let point = stack.pop() else { return nil }
        redraw()
        return point
    }
    
    open func update(_ point: CGPoint, at indexPath: IndexPath) {
        stack.update(point, at: indexPath)
        redraw()
    }
    
    open func apply(_ t: CGAffineTransform, at indexPath: IndexPath) {
        let point = stack.grid[indexPath.section][indexPath.item]
        stack.update(point.applying(t), at: indexPath)
        redraw()
    }
    
    /// Applys the given transformation to all points.
    open func apply(_ t: CGAffineTransform) {
        beginBatchUpdate()
        for (m, points) in grid.enumerated() {
            for (n, point) in points.enumerated() {
                stack.update(point.applying(t), at: IndexPath(item: n, section: m))
            }
        }
        commitBatchUpdate()
    }
    
    func markAsFinished() {
        if isCompleted && !isFinished {
            isFinished = true
        }
    }
    
    // MARK: - Drawing
    
    private func redraw() {
        if !batchUpdating {
            _mainPathWrappers = isCompleted ? mainPathWrappers() : []
            _selectedPathWrappers = isSelected && isFinished ? selectedPathWrappers() : []
            
            layer.setNeedsDisplay()
            layer.displayIfNeeded()
        }
    }
    
    private func linePathWrappers() -> [PathWrapper] {
        let path = CGMutablePath()
        for points in grid where points.count >= 2 {
            path.addLines(between: points)
        }
        return [PathWrapper(method: .dash(lineWidth, 1, [4, 4]), color: strokeColor, path: path)]
    }
    
    /// This method will only be called after `isCompleted` turns `true`.
    open func mainPathWrappers() -> [PathWrapper] {
        let path = grid.reduce(CGMutablePath()) {
            $0.addLines(between: $1)
            return $0
        }
        return [PathWrapper(method: .stroke(lineWidth), color: strokeColor, path: path)]
    }
    
    /// Draw each points in `grid`.
    open func selectedPathWrappers() -> [PathWrapper] {
        var pathWrappers = [PathWrapper]()
        if pushContinously {
            let path = mainPathWrappers().reduce(CGMutablePath()) { $0.addPath($1.path); return $0 }
            let box = path.boundingBoxOfPath.insetBy(dx: -selectionRadius, dy: -selectionRadius)
            pathWrappers.append(PathWrapper(method: .stroke(lineWidth),
                                            color: strokeColor,
                                            path: CGPath(rect: box, transform: nil)))
        } else {
            stack.grid.enumerated().forEach { i, points in
                points.enumerated().forEach { j, point in
                    let path = CGPath.box(center: grid[i][j], width: 6, rotation: 0)
                    pathWrappers.append(PathWrapper(method: .fill, color: .white, path: path))
                    pathWrappers.append(PathWrapper(method: .stroke(1), color: .black, path: path))
                }
            }
        }
        return pathWrappers
    }
    
    private func draw(in ctx: CGContext) {
        if isCompleted {
            if !isFinished {
                linePathWrappers().drawPaths(in: ctx)
            }
            _mainPathWrappers.drawPaths(in: ctx)
            _selectedPathWrappers.drawPaths(in: ctx)
        } else {
            linePathWrappers().drawPaths(in: ctx)
        }
    }
    
    // MARK: - Selection
    
    func indexOfPoint(at loc: CGPoint) -> IndexPath? {
        for (m, points) in stack.grid.enumerated() {
            for (n, point) in points.enumerated() where Line(from: point, to: loc).distance <= selectionRadius {
                return IndexPath(item: n, section: m)
            }
        }
        return nil
    }
    
    open func canSelect(by point: CGPoint) -> Bool {
        let path = mainPathWrappers().reduce(CGMutablePath()) { path, d in
            path.addPath(d.path)
            return path
        }
        .copy(strokingWithWidth: selectionRadius, lineCap: .round, lineJoin: .miter, miterLimit: selectionRadius / 2)
        return path.contains(point)
    }
    
    open func canSelect(by rect: CGRect) -> Bool {
        for points in grid {
            for point in points where rect.contains(point) {
                return true
            }
        }
        return false
    }
    
}
