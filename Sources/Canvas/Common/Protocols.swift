//
//  Protocols.swift
//  Canvas
//
//  Created by scchn on 2020/4/14.
//

#if os(OSX)
import AppKit
#else
import UIKit
#endif

public protocol Distances {
    var lines: [Line] { get }
}

public protocol Rectangular {
    var size: CGSize { get }
}

public protocol Circular {
    var circle: Circle { get }
}

@objc public protocol Angular {
    var angles: [CGFloat] { get }
    @objc optional var arcRadiusOfVertex: CGFloat { get set }
}

extension Angular {
    public var arcRadiusOfVertex: CGFloat { 15 }
}
