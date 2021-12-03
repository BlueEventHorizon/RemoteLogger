//
//  Const.swift
//  BwTools
//
//  Created by k_terada on 2020/07/08.
//  Copyright © 2020 beowulf-tech. All rights reserved.
//

import Foundation
import UIKit

public enum Const {}

extension Const {
    public enum Duration {
        public static let none: TimeInterval = 0.0
        public static let moment: TimeInterval = 0.05
        public static let fast: TimeInterval = 0.15
        public static let normal: TimeInterval = 0.30
        public static let slow: TimeInterval = 0.60
    }
}

extension Const {
    public enum Opacity {
        static let none: CGFloat = 0.0
        static let half: CGFloat = 0.5
        static let full: CGFloat = 1.0
    }
}
