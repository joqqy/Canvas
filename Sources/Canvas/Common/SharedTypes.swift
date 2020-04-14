//
//  SharedTypes.swift
//  Canvas
//
//  Created by Chen on 2020/4/15.
//

#if os(OSX)
import AppKit
#else
import UIKit
#endif

#if os(OSX)
public typealias Color = NSColor
#else
public typealias Color = UIColor
#endif

