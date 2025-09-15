//
//  AppRatingManager.swift
//  party_fun
//
//  Created by AI Assistant on 2024/10/15.
//

import Foundation
import StoreKit

class AppRatingManager {
    // 单例模式
    static let shared = AppRatingManager()
    private init() {}
    
    // UserDefaults存储键
    private let launchCountKey = "app_launch_count"
    private let buttonTapCountKey = "game_button_tap_count"
    private let hasShownRatingAlertKey = "has_shown_rating_alert"
    
    // 触发条件阈值
    private let requiredLaunchCount = 3
    private let requiredButtonTapCount = 2 // 实际上这个值是触发了几次乌龟
    
    // 获取和增加启动次数
    var launchCount: Int {
        get { UserDefaults.standard.integer(forKey: launchCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: launchCountKey) }
    }
    
    // 获取和增加乌龟点击次数
    var buttonTapCount: Int {
        get { UserDefaults.standard.integer(forKey: buttonTapCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: buttonTapCountKey) }
    }
    
    // 是否已显示过评分弹窗
    var hasShownRatingAlert: Bool {
        get { UserDefaults.standard.bool(forKey: hasShownRatingAlertKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasShownRatingAlertKey) }
    }
    
    // 增加启动次数
    func incrementLaunchCount() {
        launchCount += 1
    }
    
    // 增加按钮点击次数
    func incrementButtonTapCount() {
        buttonTapCount += 1
    }
    
    // 检查是否应该显示评分弹窗
    func shouldShowRatingAlert() -> Bool {
        // 已经显示过评分弹窗，则不再显示
        if hasShownRatingAlert {
            return false
        }
        
        // 检查是否满足触发条件
        let shouldShow = (launchCount >= requiredLaunchCount || buttonTapCount >= requiredButtonTapCount)
        
        // 如果应该显示，则标记为已显示
        if shouldShow {
            hasShownRatingAlert = true
        }
        
        return shouldShow
    }

}
