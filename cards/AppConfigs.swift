import SwiftUI

/// 应用配置参数
/// 用于统一管理应用中的UI尺寸和颜色配置
struct AppConfigs {
    
    // MARK: - 应用颜色配置
    
    /// 应用背景色
    /// 建议使用渐变色或主题色
    /// 当前值：蓝色主题
    static let appBackgroundColor: Color = .blue
    
    // MARK: - 卡片尺寸配置
    
    /// 卡片宽度
    /// 建议范围：280-360
    /// 当前值：320
    static let cardWidth: CGFloat = 320
    
    /// 卡片高度
    /// 建议范围：350-450
    /// 当前值：400
    static let cardHeight: CGFloat = 400
} 