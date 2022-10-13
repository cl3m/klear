//
//  Drag.swift
//  Klear
//
//  Created by Spencer Ward on 13/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import WidgetKit

struct Drag{

    static var cellOffsetFromCenter = CGPoint()
    static var currentIndexPath: IndexPath? = nil
    static var displayLink:CADisplayLink?
    static let scrollingRate:CGFloat = 12.0
    static var diffCurrentAndCalculatedOffset:CGFloat = 0.0
    static var currentPosition:CGPoint? = nil
//        static var isPaused = true
    static var direction:Direction = .up
}
