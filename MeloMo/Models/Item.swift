//
//  Item.swift
//  MeloMo
//
//  Created by K!MO on 8/29/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
