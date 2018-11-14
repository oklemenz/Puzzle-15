//
//  Array+Shuffle.swift
//  SlidingPuzzle
//
//  Created by Klemenz, Oliver on 17.02.15.
//  Copyright (c) 2015 Klemenz, Oliver. All rights reserved.
//

import Foundation

extension Array {
    mutating func shuffle() {
        for _ in 0..<10 {
            sort { (_,_) in arc4random() < arc4random() }
        }
    }
}
