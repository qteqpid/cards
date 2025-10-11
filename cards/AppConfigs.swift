import SwiftUI

/// 应用配置参数
/// 用于统一管理应用中的UI尺寸、颜色和文本配置
struct AppConfigs {
    
    // iphone 16的屏幕高度
    static let heightToCompared: CGFloat = 852.0
    // 根据上面高度和9:16的比例计算出来的宽度
    static let widthToCompared: CGFloat = 480.0

    // MARK: - 应用文本配置
    
    /// 应用标题
    /// 显示在主页顶部的应用名称
    /// 当前值：海龟汤
    static let appTitle: String = "海龟汤来了"
    static let appTitleSize: CGFloat = 32
    
    // MARK: - 应用颜色配置
    
    static let fontBlackColor: Color = Color(hex: "#2d2d2d")
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

    static var isIphone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    static var cardHeight: CGFloat {
        let fourSixthsHeight = screenHeight * 2/3 // 从3/5增加到2/3，提供更多显示空间
        return fourSixthsHeight
    }

    static var cardWidth: CGFloat {
        // 针对不同设备类型设置不同的卡片宽度策略
        if isIpad {
            // iPad设备：卡片宽度为屏幕宽度的60%，最小宽度400
            return min(screenWidth * 0.6, 700) // 限制最大宽度为700
        } else {
            // iPhone设备：卡片宽度为屏幕宽度减去40（左右各留20边距），最小宽度300
            return max(screenWidth - 40, 300)
        }
    }

        // 获取应用的版本号
    static var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }

    static func openUrl(url: String) {
        if let targetUrl = URL(string: url) {
            if UIApplication.shared.canOpenURL(targetUrl) {
                UIApplication.shared.open(targetUrl, options: [:], completionHandler: nil)
            }
        }
    }

    static func getAppStoreUrl(appId: String) -> String {
        if isIphone {
            return "itms-apps://itunes.apple.com/app/id\(appId)"
        } else {
            return "https://apps.apple.com/app/id\(appId)"
        }
    }

    static var cachedImages = [String: UIImage]()

    static func loadImage(name: String?) -> UIImage? {
        guard let name = name else {
            print("图片名称为空")
            return nil
        }
        // 检查缓存中是否已加载该图片
        if let cachedImage = cachedImages[name] {
            return cachedImage
        }
        // 解析文件名和扩展名
        let components = name.split(separator: ".")
        if components.count != 2 {
            print("无效的图片名称格式: \(name)")
            return nil
        }
        let imageName = String(components[0])
        let imageType = String(components[1])
        if let filePath = Bundle.main.path(forResource: imageName, ofType: imageType) {
            let image = UIImage(contentsOfFile: filePath)
            // 缓存加载的图片
            cachedImages[name] = image
            return image
        }
        print("无法加载图片"+imageName)
        return nil
    }

    static var currentBgMap: BgMap {
        // iphone 16 屏幕中心啊点 196, 426
        return BgMap(bgImage: "app_bg.png", touchpoints: [
            TouchPoint(
                name: TouchPointName.paper,
                image: "paper_ro_right.png",
                positionX: 87,
                positionY: 154,
                frameWidth: 100,
                frameHeight: 100,
                action: .displayCards),
            TouchPoint(
                name: TouchPointName.radio,
                image: "radio.png", 
                positionX: -76, 
                positionY: -41, 
                frameWidth: 100, 
                frameHeight: 100, 
                action: .toggleMusic),
            TouchPoint(
                name: TouchPointName.music,
                image: "music_symbol.png", 
                positionX: -4,
                positionY: -87,
                frameWidth: 90,
                frameHeight: 90, 
                action: nil),
            TouchPoint( 
                name: TouchPointName.turtle,
                image: "turtle_night_icon.png", 
                positionX: -100,
                positionY: -136,
                frameWidth: 50,
                frameHeight: 50,
                action: .triggerTurtle),
            TouchPoint(
                name: TouchPointName.calendar,
                image: "calendar_icon.png",
                positionX: 160,
                positionY: -275,
                frameWidth: 100,
                frameHeight: 100,
                action: .showSettings),
            TouchPoint(
                name: TouchPointName.magnifier,
                image: "magnifier_icon.png",
                positionX: 177,
                positionY: 226,
                frameWidth: 80,
                frameHeight: 80,
                action: .introduceSearch)
        ])
    }
}




// 为Color添加从十六进制字符串创建的扩展
extension Color {
    // 修复版本 - 使用非可失败初始化器，并增加对各种十六进制格式的支持
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        // 处理#前缀
        if hex.hasPrefix("#") {
            hex = String(hex.dropFirst())
        }

        // 支持3位、6位和8位十六进制格式
        var hexValue: UInt64 = 0

        if Scanner(string: hex).scanHexInt64(&hexValue) {
            var r, g, b, a: Double

            switch hex.count {
            case 3: // RGB (12-bit)
                r = Double((hexValue & 0xF00) >> 8) / 15.0
                g = Double((hexValue & 0x0F0) >> 4) / 15.0
                b = Double(hexValue & 0x00F) / 15.0
                a = 1.0
            case 6: // RGB (24-bit)
                r = Double((hexValue & 0xFF0000) >> 16) / 255.0
                g = Double((hexValue & 0x00FF00) >> 8) / 255.0
                b = Double(hexValue & 0x0000FF) / 255.0
                a = 1.0
            case 8: // RGBA (32-bit)
                r = Double((hexValue & 0xFF000000) >> 24) / 255.0
                g = Double((hexValue & 0x00FF0000) >> 16) / 255.0
                b = Double((hexValue & 0x0000FF00) >> 8) / 255.0
                a = Double(hexValue & 0x000000FF) / 255.0
            default:
                // 默认值 - 黑色
                r = 0.0
                g = 0.0
                b = 0.0
                a = 1.0
            }

            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
        } else {
            // 如果解析失败，返回黑色
            self.init(red: 0.0, green: 0.0, blue: 0.0)
        }
    }
}
