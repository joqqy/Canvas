//
//  RectSelectionItem.swift
//  Canvas
//
//  Created by scchn on 2020/4/16.
//

import CoreGraphics

class RectSelectionItem: FixedCanvasItem {
    
    var rect: CGRect? { isCompleted ? CGRect(from: grid[0][0], to: grid[0][1]) : nil }
    
    required init() {
        super.init(segments: 1, elements: 2)
        strokeColor = .white
        fillColor = Color(red: 1, green: 1, blue: 1, alpha: 0.3)
    }
    
    override func mainPathWrappers() -> [PathWrapper] {
        guard let rect = rect else { return [] }
        let path = CGPath(rect: rect, transform: nil)
        let fd = PathWrapper(method: .fill, color: fillColor, path: path)
        let sd = PathWrapper(method: .stroke(lineWidth), color: strokeColor, path: path)
        return [fd, sd]
    }
    
    func selectedItems(_ items: [CanvasItem]) -> [CanvasItem] {
        guard let rect = rect else { return [] }
        return items.filter { $0.canSelect(by: rect) }
    }
    
}
