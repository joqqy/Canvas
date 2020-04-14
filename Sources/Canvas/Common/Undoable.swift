//
//  Undoable.swift
//  Canvas
//
//  Created by Chen on 2020/4/15.
//

#if true
import Foundation

@propertyWrapper
public class Undoable<T> {
    
    public var undoManager: UndoManager = UndoManager()
    
    public var wrappedValue: T {
        didSet { registerUndoAction(oldValue) }
    }
    
    public init(_ value: T) {
        wrappedValue = value
    }
    
    private func registerUndoAction(_ value: T) {
        undoManager.registerUndo(withTarget: self) {
            $0.wrappedValue = value
        }
    }
}
#endif
