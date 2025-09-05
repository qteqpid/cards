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


struct ContentView: View {
    @StateObject private var cardManager = CardManager()
    @StateObject private var purchaseManager = InAppPurchaseManager.shared
    @State private var showPurchaseView = false
    @State private var isLoading = true
    @State private var isCardFlipped = false
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showSwipeHint = true // 控制滑动提示文字的显示
    @State private var showShareButton = true // 控制分享按钮的显示
    @State private var showSaveSuccessAlert = false // 控制保存成功提示框的显示
    @State private var showEmptyFavoritesAlert = false // 控制收藏列表为空提示框的显示
    @ObservedObject private var musicPlayer = MusicPlayer.shared
    
    var body: some View {
        ZStack {
            // 纯黑色背景
            Color.black
                .ignoresSafeArea()
            
            // 主要内容 - 不会被键盘顶起
            VStack {
                // 页面顶部：标题和分享按钮
                ZStack {
                    // 应用标题（固定在中间位置）
                    AppTitleView(purchaseManager: purchaseManager, cardManager: cardManager)
                    
                    
                    // 左侧按钮（左上角）
                    if showShareButton {
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

                            // 音乐播放按钮组件
                            MusicToggleButton(
                                musicPlayer: musicPlayer,
                                purchaseManager: purchaseManager,
                                showPurchaseView: $showPurchaseView
                            )
                            // 分享按钮
                            Button(action: {
                                captureAndSaveScreenshot()
                            }) {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: AppConfigs.buttonSize, height: AppConfigs.buttonSize)
                                    .overlay(
                                        Image(systemName: "arrowshape.turn.up.right")
                                            .font(.system(size: AppConfigs.buttonImageSize))
                                            .foregroundColor(AppConfigs.appBackgroundColor)
                                    )
                                    .shadow(radius: 5)
                            }
                            .padding(.top, 20)
                            .padding(.trailing, 20)
                        }
                    }
                }
                
                Spacer()
                if !cardManager.displayCards().isEmpty {
                    // 卡片容器
                    ZStack {
                        // 背景卡片（下一张）- 只在拖拽时显示
                        if cardManager.hasNextIndex() && abs(dragOffset) > 10 {
                            FlipCardView(card: cardManager.displayCards()[cardManager.currentIndex + 1], isFlipped: .constant(false), purchaseManager: purchaseManager, showPurchaseView: $showPurchaseView)
                                .scaleEffect(0.9)
                                .opacity(0.6)
                                .offset(x: dragOffset * 0.3)
                        }
                        
                        // 当前卡片
                        FlipCardView(card: cardManager.displayCards()[cardManager.currentIndex], isFlipped: $isCardFlipped, purchaseManager: purchaseManager, showPurchaseView: $showPurchaseView)
                            .offset(x: dragOffset)
                            .rotationEffect(.degrees(dragOffset * 0.1))
                            .scaleEffect(1.0 - abs(dragOffset) * 0.001)
                            .id(cardManager.currentIndex) // 添加id确保卡片切换时完全重建视图
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        dragOffset = value.translation.width
                                    }
                                    .onEnded { value in
                                        isDragging = false
                                        let threshold: CGFloat = 120
                                        
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            if abs(value.translation.width) > threshold {
                                                if value.translation.width > 0 && cardManager.currentIndex > 0 {
                                                    // 向右滑动，显示上一张
                                                    cardManager.decreaseIndex()
                                                    isCardFlipped = false // 重置翻面状态
                                                } else if value.translation.width < 0 && currentIndex < cardManager.displayCards().count - 1 {
                                                    if purchaseManager.shouldShowPurchaseAlert() {
                                                        showPurchaseView = true
                                                    } else {
                                                        purchaseManager.increaseUseTimes()
                                                        // 向左滑动，显示下一张
                                                        cardManager.increaseIndex()
                                                        isCardFlipped = false // 重置翻面状态
                                                        if (cardManager.currentIndex > 3) {
                                                            showSwipeHint = false // 切换后隐藏提示文字
                                                        }
                                                    }
                                                }
                                            }
                                            dragOffset = 0
                                        }
                                    }
                            )
                    }
                    
                    Spacer()
                    
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
            }
            // 搜索视图 - 独立层级，位于屏幕中下位置
            if cardManager.isSearchMode() && showShareButton {
                GeometryReader {
                    geometry in
                    HStack {
                        Spacer()
                        SearchView(cardManager: cardManager)
                            .padding(.horizontal, 20)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.7) // 定位到屏幕中下位置
                        Spacer()
                    }
                }
            }
            
        } 
        // .ignoresSafeArea(.keyboard) // 移除全局的键盘安全区域忽略
        .environmentObject(cardManager)
        // 弹窗和页面修饰符
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
        .sheet(isPresented: $showPurchaseView) { 
            PurchaseView(purchaseManager: purchaseManager)
        }
    }


     // 捕获并保存截图到相册的方法
    private func captureAndSaveScreenshot() {
        // 检查相册权限
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                // 如果用户拒绝授权，可以显示提示
                DispatchQueue.main.async {
                    // 这里可以添加一个提示，告知用户需要授权才能保存到相册
                    print("需要相册权限才能保存截图")
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
                        if let stampImage = AppConfigs.loadImage(imageName: "stamp_1", imageType: "png") {
                            let stampRect = CGRect(
                                x: window.bounds.width - stampImage.size.width - 50,
                                y: window.bounds.height - stampImage.size.height - 170,
                                width: stampImage.size.width,
                                height: stampImage.size.height
                            )
                            stampImage.draw(in: stampRect)
                        }
                        // 加载二维码图片并绘制在右下角
                        if let qrCodeImage = AppConfigs.loadImage(imageName: "qr_code", imageType: "png") {
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
