import SwiftUI

/// 应用配置参数
/// 用于统一管理应用中的UI尺寸、颜色和文本配置
struct AppConfigs {
    
    // MARK: - 应用文本配置
    
    /// 应用标题
    /// 显示在主页顶部的应用名称
    /// 当前值：海龟汤
    static let appTitle: String = "海龟汤来了"
    static let appTitleSize: CGFloat = 32
    
    // MARK: - 应用颜色配置
    
    /// 应用主题色
    /// 当前值：黑色主题
    static let appBackgroundColor: Color = .black

    // 顶部按钮大小
    static let buttonSize: CGFloat = 28
    static let buttonImageSize: CGFloat = 18

    
    static var startTitleFontSize: CGFloat {
        return isIpad ? 36 : 24
    }
    
    static var startFontSize: CGFloat {
        return startTitleFontSize * 0.75
    }
    
    static var startButtonFontSize: CGFloat {
        return isIpad ? 36 : 18
    }
    
    
    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var cardHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let fourSixthsHeight = screenHeight * 2/3 // 从3/5增加到2/3，提供更多显示空间
        return fourSixthsHeight
    }

    static var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        // 针对不同设备类型设置不同的卡片宽度策略
        if isIpad {
            // iPad设备：卡片宽度为屏幕宽度的60%，最小宽度400
            return min(screenWidth * 0.6, 700) // 限制最大宽度为700
        } else {
            // iPhone设备：卡片宽度为屏幕宽度减去40（左右各留20边距），最小宽度300
            return max(screenWidth - 40, 300)
        }
    }
    
    static func loadImage(imageName: String, imageType: String) -> UIImage? {
        // 从bundle直接加载图片
        if let filePath = Bundle.main.path(forResource: imageName, ofType: imageType) {
            return UIImage(contentsOfFile: filePath)
        }
        print("无法加载图片"+imageName)
        return nil
    }
}
