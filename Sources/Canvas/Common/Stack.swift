//
//  Stack.swift
//  Canvas
//
//  Created by scchn on 2020/4/14.
//

import Foundation
import CoreGraphics

public class Stack {
    
    public typealias Grid = [[CGPoint]]
    
    public private(set) var grid: Grid = []
    
    public var endIndexPath: IndexPath? {
        guard !grid.isEmpty && grid.last?.isEmpty == false else { return nil }
        let s = grid.count - 1
        let i = grid[s].count - 1
        return IndexPath(item: i, section: s)
    }
    
    // MARK: - Push
    
    public func push(_ point: CGPoint) {
        if grid.last == nil { grid.append([]) }
        grid[grid.index(before: grid.endIndex)].append(point)
    }
    
    public func pushToNext(_ point: CGPoint) {
        guard grid.last == nil || grid.last?.isEmpty == false else { return }
        grid.append([])
        push(point)
    }
    
    // MARK: - Update
    
    public func update(_ point: CGPoint, at indexPath: IndexPath) {
        grid[indexPath.section][indexPath.item] = point
    }
    
    // MARK: - Pop
    
    public func canPop() -> Bool { grid.last?.last != nil }
    
    @discardableResult
    public func pop() -> CGPoint? {
        guard var points = grid.last else { return nil }
        let idx = grid.count - 1
        let removed = points.removeLast()
        grid[idx] = points
        if points.isEmpty {
            grid.removeLast()
        }
        return removed
    }
    
}
