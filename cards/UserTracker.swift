//
//  AppRatingManager.swift
//  party_fun
//
//  Created by AI Assistant on 2024/10/15.
//

import Foundation
import StoreKit

class UserTracker {
    // 单例模式
    static let shared = UserTracker()
    private init() {}
    
    // UserDefaults存储键
    private let enteredMapKey = "entered_map"

    private let shownInstructionKey = "shown_instruction"
    
    private let firstViewSoupKey = "first_view_soup"
    
    // 检查是否已进入地图
    var hasEnteredMap: Bool {
        get { UserDefaults.standard.bool(forKey: enteredMapKey) }
        set { UserDefaults.standard.set(newValue, forKey: enteredMapKey) }
    }

    var hasShownInstruction: Bool {
        get { UserDefaults.standard.bool(forKey: shownInstructionKey) }
        set { UserDefaults.standard.set(newValue, forKey: shownInstructionKey) }
    }
    
    var isFirstViewSoup: Bool {
        get { UserDefaults.standard.bool(forKey: firstViewSoupKey) == false }
        set { UserDefaults.standard.set(!newValue, forKey: firstViewSoupKey) }
    }
}
