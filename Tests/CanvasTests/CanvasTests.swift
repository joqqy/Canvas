import XCTest
@testable import Canvas

#if true
final class UndoableTests: XCTestCase {
    
    @Undoable(1) var undoableValue: Int
    
    func testUndoable() {
        let oldValue = undoableValue
        let newValue = 2
        let undoManager = UndoManager()
        _undoableValue.undoManager = undoManager
        undoableValue = newValue
        // Undo
        XCTAssertTrue(undoManager.canUndo)
        undoManager.undo()
        XCTAssertEqual(undoableValue, oldValue)
        // Redo
        XCTAssertTrue(undoManager.canRedo)
        undoManager.redo()
        XCTAssertEqual(undoableValue, newValue)
        //
        undoableValue = 3
        undoableValue = 4
        XCTAssertTrue(undoManager.canUndo)
        undoManager.undo()
        XCTAssertTrue(undoManager.canUndo)
        undoManager.undo()
        XCTAssertEqual(undoableValue, 1)
        XCTAssertTrue(undoManager.canRedo)
        undoableValue = 2
        XCTAssertFalse(undoManager.canRedo)
    }
    
}
#endif

func genStackTestResult(nums: [Int]) -> [[CGPoint]] {
    nums.reduce([[CGPoint]]()) { $0 + [[CGPoint](repeating: .zero, count: $1)] }
}

final class StackTests: XCTestCase {
    
    func testStack() {
        let stack = Stack()
        XCTAssertFalse(stack.canPop())
        XCTAssertNil(stack.pop())
        XCTAssertNil(stack.endIndexPath)
        stack.pushToNext(.zero)
        XCTAssertEqual(stack.grid, genStackTestResult(nums: [1]))
        stack.push(.zero)
        XCTAssertEqual(stack.grid, genStackTestResult(nums: [2]))
        stack.pushToNext(.zero)
        XCTAssertEqual(stack.grid, genStackTestResult(nums: [2, 1]))
        XCTAssertTrue(stack.canPop())
        XCTAssertNotNil(stack.pop())
        XCTAssertEqual(stack.grid, genStackTestResult(nums: [2]))
    }
    
}

final class DrawerTests: XCTestCase {
    
    func testUndoRedoActionsForUpdate() {
        let item = CanvasItem()
        let undoManager = UndoManager()
        let old: [[CGPoint]] = [[.zero]]
        let p = CGPoint(x: 1, y: 1)
        let new: [[CGPoint]] = [[p]]
        item.undoManager = undoManager
        item.push(.zero)
        item.markAsFinished()
        item.update(CGPoint(x: 1, y: 1), at: item.endIndexPath!)
        XCTAssertEqual(item.grid, new)
        XCTAssertTrue(undoManager.canUndo)
        undoManager.undo()
        XCTAssertEqual(item.grid, old)
        XCTAssertTrue(undoManager.canRedo)
        undoManager.redo()
        XCTAssertEqual(item.grid, new)
        XCTAssertTrue(undoManager.canUndo)
        undoManager.undo()
        item.update(.zero, at: item.endIndexPath!)
        XCTAssertFalse(undoManager.canRedo)
    }
    
    func testUndoRedoActionsForTransformation() {
        let item = CanvasItem()
        let t = CGAffineTransform.identity.translatedBy(x: 1, y: 1)
        let undoManager = UndoManager()
        let old: [[CGPoint]] = [[.zero, .zero]]
        let new = [[CGPoint(x: 1, y: 1), CGPoint(x: 1, y: 1)]]
        item.undoManager = undoManager
        item.push(.zero)
        item.push(.zero)
        item.markAsFinished()
        item.apply(t)
        XCTAssertEqual(item.grid, new)
        XCTAssertTrue(undoManager.canUndo)
        undoManager.undo()
        XCTAssertEqual(item.grid, old)
        XCTAssertTrue(undoManager.canRedo)
        undoManager.redo()
        XCTAssertEqual(item.grid, new)
        XCTAssertTrue(undoManager.canUndo)
        undoManager.undo()
        item.apply(CGAffineTransform(scaleX: 2, y: 2))
        XCTAssertFalse(undoManager.canRedo)
    }
    
    func testFixedCanvasItem() {
        let d = FixedCanvasItem(segments: 2, elements: 2)
        d.push(.zero)
        XCTAssertEqual(d.grid, genStackTestResult(nums: [1]))
        d.push(.zero)
        d.push(.zero)
        XCTAssertEqual(d.grid, genStackTestResult(nums: [2, 1]))
        XCTAssertNotNil(d.pop())
        d.pushToNextSegment(.zero)
        XCTAssertEqual(d.grid, genStackTestResult(nums: [2, 1]))
        d.push(.zero)
        d.push(.zero)
        XCTAssertEqual(d.grid, genStackTestResult(nums: [2, 2]))
    }
    
    func testFlexSegCanvasItem() {
        let d = FlexSegCanvasItem(elements: 2)
        d.push(.zero)
        d.push(.zero)
        d.push(.zero)
        d.push(.zero)
        XCTAssertEqual(d.grid, genStackTestResult(nums: [2, 2]))
    }
    
    func testFlexEleCanvasItem() {
        let d = FlexEleCanvasItem(segments: 2)
        d.push(.zero)
        d.pushToNextSegment(.zero)
        d.push(.zero)
        d.push(.zero)
        d.pushToNextSegment(.zero)
        XCTAssertEqual(d.grid, genStackTestResult(nums: [1, 3, 1]))
    }
    
}

final class CanvasViewTests: XCTestCase {
    
    class MCanvasView: CanvasView {
        let _undoManager = UndoManager()
        override var undoManager: UndoManager? { _undoManager }
    }
    
    let canvasView = MCanvasView()
    
    func testAddItem() {
        let item = CanvasItem()
        item.push(.zero)
        canvasView.addItem(item)
        XCTAssertEqual(canvasView.items.count, 1)
    }
    
}
