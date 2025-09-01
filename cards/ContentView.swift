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

// 加载图片的方法
private func loadImage(imageName: String, imageType: String) -> UIImage? {
    // 从bundle直接加载图片
    if let filePath = Bundle.main.path(forResource: imageName, ofType: imageType) {
        return UIImage(contentsOfFile: filePath)
    }
    print("无法加载图片"+imageName)
    return nil
}

struct ContentView: View {
    @StateObject private var cardManager = CardManager()
    @StateObject private var purchaseManager = InAppPurchaseManager.shared
    @State private var showPurchaseView = false
    @State private var isLoading = true
    @State private var isCardFlipped = false
    @State private var currentIndex = 0
    @State private var currentAllIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showSwipeHint = true // 控制滑动提示文字的显示
    @State private var showShareButton = true // 控制分享按钮的显示
    @State private var showSaveSuccessAlert = false // 控制保存成功提示框的显示
    @State private var showEmptyFavoritesAlert = false // 控制收藏列表为空提示框的显示
    
    // 音乐播放相关状态
    // 音乐播放器实例
    @ObservedObject private var musicPlayer = MusicPlayer.shared
    
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
                        if let stampImage = loadImage(imageName: "stamp", imageType: "png") {
                            let stampRect = CGRect(
                                x: window.bounds.width - stampImage.size.width - 50,
                                y: window.bounds.height - stampImage.size.height - 170,
                                width: stampImage.size.width,
                                height: stampImage.size.height
                            )
                            stampImage.draw(in: stampRect)
                        }
                        // 加载二维码图片并绘制在右下角
                        if let qrCodeImage = loadImage(imageName: "haigui", imageType: "png") {
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
    
    var body: some View {
        ZStack {
            // 纯黑色背景
            Color.black
                .ignoresSafeArea()
            
            // 加载状态
            if cardManager.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: AppConfigs.appBackgroundColor))
                    Text("加载卡片数据...")
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
            }
            
            // 错误状态
            else if let errorMessage = cardManager.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("加载失败")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("重新加载") {
                        cardManager.reloadCards()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white, lineWidth: 2)
                    )
                }
            }
            
            // 正常内容
            else if !cardManager.displayCards().isEmpty {            
                VStack {
                    // 页面顶部：标题和分享按钮
                    ZStack {
                        // 应用标题（固定在中间位置）
                        Text(AppConfigs.appTitle)
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.purple,
                                        Color.blue,
                                        Color.cyan
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            // 后门：长按5秒设置为会员
                            .gesture(
                                LongPressGesture(minimumDuration: 5)
                                    .onEnded { _ in
                                        purchaseManager.activatePremium()
                                    }
                            )
                            .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 6)
                            .padding(.top, 20)
                            .padding(.bottom, 0)
                        
                        // 左侧按钮（左上角）
                        
                        if showShareButton {
                            HStack {
                                // 收藏/首页切换按钮
                                Button(action: {
                                    // 切换卡片来源
                                    if cardManager.isFavoriteMode() {
                                        cardManager.switchCardSource(to: .all)
                                        // 重置当前卡片索引，确保从之前位置开始显示
                                        currentIndex = currentAllIndex
                                        // 重置翻面状态
                                        isCardFlipped = false
                                    } else {
                                        // 检查收藏列表是否为空
                                        if cardManager.favoriteCardIds.isEmpty {
                                            // 显示提示框
                                            showEmptyFavoritesAlert = true
                                        } else {
                                            cardManager.switchCardSource(to: .favorite)
                                            // 重置当前卡片索引，确保从第一张开始显示
                                            currentAllIndex = currentIndex
                                            currentIndex = 0
                                            // 重置翻面状态
                                            isCardFlipped = false
                                        }
                                    }
                                }) {
                                    // 根据当前模式显示不同内容
                                    if cardManager.isFavoriteMode() {
                                        Text("返回")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Circle()
                                            .fill(Color.white.opacity(0.8))
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.red)
                                            )
                                            .shadow(radius: 5)
                                    }
                                }
                                .padding(.top, 20)
                                .padding(.leading, 20)
                                
                                // 音乐播放/暂停按钮
                                Button(action: {
                                    musicPlayer.togglePlayback()
                                }) {
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Image(systemName: musicPlayer.isPlaying ? "music.note" : "music.note.slash")
                                                .font(.system(size: 16))
                                                .foregroundColor(AppConfigs.appBackgroundColor)
                                        )
                                        .shadow(radius: 5)
                                }
                                .padding(.top, 20)
                            
                                Spacer()

                                // 分享按钮
                                Button(action: {
                                    captureAndSaveScreenshot()
                                }) {
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Image(systemName: "arrowshape.turn.up.right")
                                                .font(.system(size: 20))
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
                    
                    // 卡片容器
                    ZStack {
                        // 背景卡片（下一张）- 只在拖拽时显示
                        if currentIndex < cardManager.displayCards().count - 1 && abs(dragOffset) > 10 {
                            FlipCardView(card: cardManager.displayCards()[currentIndex + 1], isFlipped: .constant(false), purchaseManager: purchaseManager, showPurchaseView: $showPurchaseView)
                                .scaleEffect(0.9)
                                .opacity(0.6)
                                .offset(x: dragOffset * 0.3)
                        }
                        
                        // 当前卡片
                        FlipCardView(card: cardManager.displayCards()[currentIndex], isFlipped: $isCardFlipped, purchaseManager: purchaseManager, showPurchaseView: $showPurchaseView)
                            .offset(x: dragOffset)
                            .rotationEffect(.degrees(dragOffset * 0.1))
                            .scaleEffect(1.0 - abs(dragOffset) * 0.001)
                            .id(currentIndex) // 添加id确保卡片切换时完全重建视图
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
                                                if value.translation.width > 0 && currentIndex > 0 {
                                                    // 向右滑动，显示上一张
                                                    currentIndex -= 1
                                                    isCardFlipped = false // 重置翻面状态
                                                } else if value.translation.width < 0 && currentIndex < cardManager.displayCards().count - 1 {
                                                    if purchaseManager.shouldShowPurchaseAlert() {
                                                        showPurchaseView = true
                                                    } else {
                                                        purchaseManager.increaseUseTimes()
                                                        // 向左滑动，显示下一张
                                                        currentIndex += 1
                                                        isCardFlipped = false // 重置翻面状态
                                                        if (currentIndex > 3) {
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
                        currentPage: currentIndex
                    )
                    
                    // 滑动提示文字 - 根据状态变量条件显示
                    Text(showSwipeHint ? "左右滑动纸张切换题目" : "")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 10)
                }.alert("保存成功", isPresented: $showSaveSuccessAlert) {
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
        } .environmentObject(cardManager)
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

struct FlipCardView: View {
    let card: Card
    @Binding var isFlipped: Bool
    @State private var showDescription = false // 控制描述文本的显示
    @State private var animationTimer: Timer? = nil
    @ObservedObject var purchaseManager: InAppPurchaseManager
    @Binding var showPurchaseView: Bool
    
    var body: some View {
        ZStack {
            // 正面
            CardFrontView(cardSide: card.front, cardId: card.id, author: card.author)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 0 : 1)
            
            // 背面
            CardBackView(cardSide: card.back)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.8)) {                
                // 点击卡片时检查是否需要显示购买提醒
                if purchaseManager.shouldShowPurchaseAlert() {
                    showPurchaseView = true
                } else {
                    purchaseManager.increaseUseTimes()
                    isFlipped.toggle()
                    resetDescriptionVisibility() // 重置描述文本的显示状态
                }
            }
        }
        .onAppear {
            resetDescriptionVisibility() // 卡片出现时重置描述文本的显示状态
        }
        .environment(\.isDescriptionVisible, showDescription)
    }
    
    // 重置描述文本的显示状态，1秒后显示
    private func resetDescriptionVisibility() {
        showDescription = false
        
        // 移除之前的计时器
        animationTimer?.invalidate()
        
        // 设置1秒后显示描述文本
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
            _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                showDescription = true
            }
        }
    }
}

struct CardFrontView: View {
    let cardSide: CardSide
    let cardId: Int // 卡片ID
    let author: String?
    @Environment(\.isDescriptionVisible) private var isDescriptionVisible // 从环境中获取描述文本的显示状态
    @State private var showHeartAnimation = false // 控制爱心动画的显示状态
    @State private var heartScale: CGFloat = 0 // 控制爱心的缩放比例
    @EnvironmentObject private var cardManager: CardManager // 使用环境对象访问CardManager
    


    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()
                
                // 内容区域
                VStack(spacing: 20) {
                    // 图标 - 只在有图标时显示
                    if let icon = cardSide.icon {
                        ZStack {
                            Circle()
                                .fill(AppConfigs.appBackgroundColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: icon)
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(AppConfigs.appBackgroundColor)
                        }
                    }
                    
                    // 标题
                    if let title = cardSide.title {
                        VStack {
                            Text(title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            if let author {
                                Text("by "+author)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .opacity(0.8)
                            }
                        }
                    }
                    
                    // 描述 - 只在有描述时显示
                    if let description = cardSide.description {
                        ScrollView {
                            Text(description)
                                .font(.title2)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .opacity(isDescriptionVisible ? 1 : 0) // 根据状态控制透明度
                                .scaleEffect(isDescriptionVisible ? 1 : 0.95) // 根据状态控制缩放
                        }
                        .layoutPriority(1)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 10)
                    }
                }
                
                Spacer()
                // 提示文字
                Text("点击纸张查看汤底")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.bottom, 0)
            }
            .padding(30)
            .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
            .background(CardBackgroundView())
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(AppConfigs.appBackgroundColor.opacity(0.2), lineWidth: 1)
            )
            
            // 在收藏模式下显示浮动的收藏图标，位于卡片左上角
            if cardManager.isFavoriteMode() {
                if let favoriteImage = loadImage(imageName: "favorite", imageType: "png") {
                    Image(uiImage: favoriteImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .position(x: 60, y: 60)
                        .opacity(0.6)
                        .transition(.scale)
                }
            } else {
                if let author, let originalImage = loadImage(imageName: "original", imageType: "png") {
                    Image(uiImage: originalImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .position(x: 60, y: 60)
                        .opacity(0.6)
                        .transition(.scale)
                }
            }
        }
        .onTapGesture(count: 2) { // 添加双击手势
                withAnimation {
                    showHeartAnimation = true
                    
                    // 将卡片ID添加到收藏列表中（如果尚未收藏）
                    if !cardManager.isFavorite(cardId: cardId) {
                        cardManager.addToFavorites(cardId: cardId)
                        print("已收藏卡片 ID: \(cardId)")
                        print("当前收藏列表: \(cardManager.favoriteCardIds)")
                    } else {
                        print("卡片 ID: \(cardId) 已在收藏列表中")
                    }
                    
                    // 第一阶段：从0放大到1.2
                withAnimation(Animation.easeOut(duration: 0.5)) {
                    heartScale = 1.2
                }
                
                // 第二阶段：从1.2稍微缩小到1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(Animation.easeIn(duration: 0.3)) {
                        heartScale = 1.0
                    }
                }
                
                // 0.5秒后隐藏爱心
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(Animation.easeOut(duration: 0.3)) {
                        heartScale = 0
                        showHeartAnimation = false
                    }
                }
            }
        }
        .overlay( // 添加爱心动画覆盖层
            ZStack {
                if showHeartAnimation {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(Color.red)
                        .opacity(0.8)
                        .scaleEffect(heartScale)
                }
            }
        )
    }
    
    
}

struct CardBackView: View {
    let cardSide: CardSide
    // 移除环境变量引用，不再使用延迟显示效果
    
    var body: some View {
        VStack(spacing: 20) {
            // 背面图标 - 只在有图标时显示
            if let icon = cardSide.icon {
                ZStack {
                    Circle()
                        .fill(AppConfigs.appBackgroundColor.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(AppConfigs.appBackgroundColor)
                }
            }
            
            // 背面标题 - 独立显示
            if let title = cardSide.title {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            
            
            // 背面描述 - 只在有描述时显示
            if let description = cardSide.description {
                ScrollView {
                    Text(description)
                        .font(.title2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                }
                .layoutPriority(1)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 10)
            }
            
            // 提示文字
            Text("点击纸张翻回汤面")
                .font(.caption)
                .foregroundColor(.primary)
                .padding(.bottom, 0)
        }
        .padding(30)
        .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
        .background(CardBackgroundView())
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(AppConfigs.appBackgroundColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// 创建共用的卡片背景视图组件
struct CardBackgroundView: View {
    var body: some View {
        ZStack {
            // 先添加一个黑色背景，让透明的PNG图片能够更好地与应用黑色背景融合
            Color.black
                .clipShape(RoundedRectangle(cornerRadius: 25))
            
            // 通过Bundle文件路径加载图片
            if let image = loadImage(imageName: "paper", imageType: "jpg") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            } else {
                // 如果加载失败，显示一个备用的米色背景
                Color(red: 0.94, green: 0.91, blue: 0.81)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            
            // 添加卡片边框和阴影
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                .shadow(color: AppConfigs.appBackgroundColor.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CardManager())
}
