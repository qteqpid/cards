//
//  ContentView.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI
import UIKit
import Photos
import AVFoundation
import StoreKit

// UIImageView包装器，用于在SwiftUI中使用UIKit的UIImageView
struct UIImageViewWrapper: UIViewRepresentable {
    let image: UIImage
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: image)
        // 设置为等比例缩放并填充整个区域
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // 允许SwiftUI控制大小
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
    }
    
    // 使UIView能够响应SwiftUI的布局提议
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        // 使用父视图提议的尺寸
        if let width = proposal.width, let height = proposal.height {
            return CGSize(width: width, height: height)
        }
        // 否则返回图片的原始尺寸
        return uiView.image?.size ?? CGSize.zero
    }
}

struct ContentView: View {
    @Environment(\.requestReview) var requestReview
    @StateObject private var cardManager = CardManager()
    @StateObject private var purchaseManager = InAppPurchaseManager.shared
    @State private var showPurchaseView = false
    @State private var isLoading = true
    @State private var isCardFlipped = false
    // 移除本地currentIndex状态变量，直接使用cardManager.currentIndex
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showSwipeHint = true // 控制滑动提示文字的显示
    @State private var showShareButton = true // 控制分享按钮的显示
    @State private var showSaveSuccessAlert = false // 控制保存成功提示框的显示
    @State private var showEmptyFavoritesAlert = false // 控制收藏列表为空提示框的显示
    @State private var showRatingAlert = false // 控制是否显示评分邀请弹窗
    @State private var showSettings = false // 控制是否显示settings
    @State private var showScrollView = true // 控制ScrollView的显示/隐藏
    @State private var showPhotoPermissionAlert = false // 控制相册权限提示Alert的显示
    // 添加对TurtleBot的观察，确保UI正确响应isVisible的变化
    @ObservedObject private var turtleBot = TurtleBot.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // touchpoints层
                TouchPointsLayerView(showScrollView: $showScrollView, showRatingAlert: $showRatingAlert, showSettings: $showSettings)
            
                VStack {
                    // 导航栏 - 使用ZStack实现标题严格居中
                    ZStack {
                        // 标题层 - 严格居中
                        AppTitleView(cardManager: cardManager)
                        
                        // 按钮层
                        if showShareButton {
                            HeadButtonsView(
                                cardManager: cardManager,
                                purchaseManager: purchaseManager,
                                isCardFlipped: $isCardFlipped,
                                showEmptyFavoritesAlert: $showEmptyFavoritesAlert,
                                showPurchaseView: $showPurchaseView,
                                showScrollView: $showScrollView,
                                captureAndSaveScreenshot: captureAndSaveScreenshot
                            )
                        }
                    }
                    .padding()

                    Spacer()
                    
                    ScrollView {
                        if !cardManager.displayCards().isEmpty {
                            CardView(
                                    cardManager: cardManager,
                                    purchaseManager: purchaseManager,
                                    dragOffset: $dragOffset,
                                    isDragging: $isDragging,
                                    isCardFlipped: $isCardFlipped,
                                    showPurchaseView: $showPurchaseView,
                                    showSwipeHint: $showSwipeHint
                                )
                            
                            Spacer(minLength: 20)
                            
                            // 分页指示器
                            PageIndicatorView(
                                totalPages: cardManager.displayCards().count,
                                currentPage: cardManager.currentIndex
                            )
                            
                            // 滑动提示文字 - 根据状态变量条件显示
                            Text(showSwipeHint ? "左右滑动纸张切换题目" : "")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.bottom, 10)
                        } else {
                            if (cardManager.isFavoriteMode()) {
                                // 当没有符合条件的卡片时显示提示文字
                                Text("没有收藏的汤了，快回主页收藏一些吧")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            } else {
                                // 当没有符合条件的卡片时显示提示文字
                                Text("没有找到符合条件的汤")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                            
                            Spacer()
                        }
                    }.id(cardManager.displayCards().isEmpty ? -1 : cardManager.displayCards()[cardManager.currentIndex].id) // 添加id确保模式切换时完全重建ScrollView
                    
                    Spacer()
                    
                }.opacity(showScrollView ? 1 : 0)
                .scaleEffect(showScrollView ? 1 : 0.2) // 从1.2缩放到0.2，变化更明显
                .animation(.easeIn(duration: 0.6), value: showScrollView) // 稍微延长动画时间
                // 龟龟视图 - 独立层级，位于屏幕中下位置
                if turtleBot.isInScenarioOf(scenario: Scenario.notification) { // 使用@ObservedObject的turtleBot属性而不是直接使用TurtleBot.shared
                    HStack {
                        Spacer()
                        TurtleNotificationView(cardManager: cardManager)
                        Spacer()
                    }
                } else if turtleBot.isInScenarioOf(scenario: Scenario.challenge) {
                    HStack {
                        Spacer()
                        TurtleJudgeView(cardManager: cardManager)
                            .id("turtle-judge-\(cardManager.cardSource)-\(cardManager.currentIndex)") // 添加id确保模式切换时重新创建
                        Spacer()
                    }
                }
            }
            .background {
                if let image = AppConfigs.loadImage(name: AppConfigs.currentBgMap.bgImage) {
                    UIImageViewWrapper(image: image)
                        .ignoresSafeArea()
                }
            }
            // .ignoresSafeArea(.keyboard) // 移除全局的键盘安全区域忽略
            .environmentObject(cardManager)
            // 弹窗和页面修饰符
            .onChange(of: cardManager.isAllMode() && showScrollView) { newValue in
                if newValue {
                    TurtleBot.shared.switchToScenario(scenario: .challenge)
                } else {
                    TurtleBot.shared.hide()
                }
            }
            .alert("保存成功", isPresented: $showSaveSuccessAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("已保存到相册里，快去分享给好友吧!")
            }
            .alert("当前收藏为空", isPresented: $showEmptyFavoritesAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("请双击纸张收藏喜欢的海龟汤题目吧!")
            }
            .alert("需要相册权限", isPresented: $showPhotoPermissionAlert) {
                Button("取消", role: .cancel) {}
                Button("去设置") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("需要访问相册权限才能保存截图，请在设备设置中修改。")
            }
            .alert("喜欢这个app的设计吗？", isPresented: $showRatingAlert) {
                Button("不喜欢") {}
                Button("喜欢") {
                    requestReview()
                }
            } message: {
                Text("觉得还不错的话帮忙打个分吧~ 😘")
                    .font(.body)
                    .foregroundColor(Color.primary)
            }
            .sheet(isPresented: $showPurchaseView) {
                PurchaseView(purchaseManager: purchaseManager, showRatingAlert: $showRatingAlert)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(purchaseManager: purchaseManager, backgroundColor: Color(hex: "#2d2d2d"))
            }
        }
        .onAppear {
            TurtleBot.shared.switchToScenario(scenario: .challenge)
        }
    }


     // 捕获并保存截图到相册的方法
    private func captureAndSaveScreenshot() {
        // 检查相册权限
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                // 如果用户拒绝授权，显示提示Alert
                DispatchQueue.main.async {
                    self.showPhotoPermissionAlert = true
                }
                return
            }
            
            // 延迟执行，确保UI已经稳定
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 隐藏分享按钮防止它出现在截图中
                self.showShareButton = false
                
                // 再次延迟，确保按钮已经隐藏
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 创建一个视图控制器
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else {
                        self.showShareButton = true
                        return
                    }
                    
                    // 捕获当前视图的截图，并添加二维码
                    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
                    let screenshot = renderer.image { context in
                        // 先绘制主界面
                        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                        
                        // 加载stamp图片并绘制在右下角
                        if let stampImage = AppConfigs.loadImage(name: "stamp_1.png") {
                            let stampRect = CGRect(
                                x: window.bounds.width - stampImage.size.width - 50,
                                y: window.bounds.height - stampImage.size.height - 170,
                                width: stampImage.size.width,
                                height: stampImage.size.height
                            )
                            stampImage.draw(in: stampRect)
                        }
                        // 加载二维码图片并绘制在右下角
                        if let qrCodeImage = AppConfigs.loadImage(name: "qr_code.png") {
                            let qrCodeSize: CGFloat = 60 // 二维码大小
                            let margin: CGFloat = 40 // 距离边缘的边距
                            let textHeight: CGFloat = 20 // 文字高度

                            // 绘制二维码图片
                            let qrCodeRect = CGRect(
                                x: window.bounds.width - qrCodeSize - margin,
                                y: window.bounds.height - qrCodeSize - margin,
                                width: qrCodeSize,
                                height: qrCodeSize
                            )
                            qrCodeImage.draw(in: qrCodeRect)

                            // 在二维码上方绘制文字
                            let text = "扫描二维码"
                            let textAttributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 12),
                                .foregroundColor: UIColor.white
                            ]
                            let textSize = text.size(withAttributes: textAttributes)
                            let textRect = CGRect(
                                x: window.bounds.width - textSize.width - margin,
                                y: qrCodeRect.origin.y - textHeight - 2,
                                width: textSize.width,
                                height: textHeight
                            )
                            text.draw(in: textRect, withAttributes: textAttributes)
                        }
                    }
                    
                    // 保存截图到相册
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: screenshot)
                    } completionHandler: { success, error in
                        DispatchQueue.main.async {
                            // 恢复分享按钮的显示
                            self.showShareButton = true
                            
                            if success {
                                // 可以添加成功提示
                                print("截图已保存到相册")
                                self.showSaveSuccessAlert = true
                            } else {
                                // 可以添加失败提示
                                print("保存截图失败：\(error?.localizedDescription ?? "未知错误")")
                            }
                        }
                    }
                }
            }
        }
    }
}

// 头部按钮视图组件
struct HeadButtonsView: View {
    let cardManager: CardManager
    let purchaseManager: InAppPurchaseManager
    @Binding var isCardFlipped: Bool
    @Binding var showEmptyFavoritesAlert: Bool
    @Binding var showPurchaseView: Bool
    @Binding var showScrollView: Bool
    let captureAndSaveScreenshot: () -> Void
    
    var body: some View {
        HStack {
            // 收藏/首页切换按钮
            FavoriteButtonView(
                cardManager: cardManager,
                purchaseManager: purchaseManager,
                isCardFlipped: $isCardFlipped,
                showEmptyFavoritesAlert: $showEmptyFavoritesAlert,
                showPurchaseView: $showPurchaseView
            )
            
            Spacer()

            // 地图按钮组件
            Button(action: {
                if purchaseManager.shouldShowPurchaseAlert() {
                    showPurchaseView = true
                } else {
                    showScrollView = false
                    if !UserTracker.shared.hasEnteredMap {
                        // 未进入过地图，这是第一次
                        UserTracker.shared.hasEnteredMap = true
                        // 添加1秒延迟后再执行
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            TurtleBot.shared.switchToScenario(scenario: Scenario.notification)
                            TurtleBot.shared.speak(TurtleBot.shared.getDoctorKnowledge())
                        }
                    }
                }
            }) {
                
                if let mapIcon = AppConfigs.loadImage(name: "map_icon.png") {
                    Image(uiImage: mapIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: AppConfigs.buttonSize, height: AppConfigs.buttonSize)
                }
            }
            
            // 截图分享按钮
            Button(action: {
                captureAndSaveScreenshot()
            }) {
                if let mapIcon = AppConfigs.loadImage(name: "share_icon.png") {
                    Image(uiImage: mapIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: AppConfigs.buttonSize, height: AppConfigs.buttonSize)
                }
            }
            .padding(.trailing, 20)
        }
    }
}

// 环境键定义，用于控制描述文本的显示状态
private struct IsDescriptionVisibleKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var isDescriptionVisible: Bool {
        get { self[IsDescriptionVisibleKey.self] }
        set { self[IsDescriptionVisibleKey.self] = newValue }
    }
}

#Preview {
    ContentView()
        .environmentObject(CardManager())
}
