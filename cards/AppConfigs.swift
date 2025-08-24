import SwiftUI

/// 应用配置参数
/// 用于统一管理应用中的UI尺寸、颜色和文本配置
struct AppConfigs {
    
    // MARK: - 应用文本配置
    
    /// 应用标题
    /// 显示在主页顶部的应用名称
    /// 当前值：海龟汤
    static let appTitle: String = "海龟汤"
    
    // MARK: - 应用颜色配置
    
    /// 应用主题色
    /// 当前值：黑色主题
    static let appBackgroundColor: Color = .black
    
    
    static var cardHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let fourSixthsHeight = screenHeight * 2/3 // 从3/5增加到2/3，提供更多显示空间
        return fourSixthsHeight
    }

    static var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let halfScreenWidth = screenWidth / 2
        return max(screenWidth - 40, halfScreenWidth)
    }
}
