//
//  ContentView.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var cardManager = CardManager()
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isCardFlipped = false
    @State private var showSwipeHint = true // 控制滑动提示文字的显示
    
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
            else if !cardManager.cards.isEmpty {            
            VStack {
                // 应用标题
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
                    .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 6)
                    .padding(.top, 20)
                    .padding(.bottom, 0)
                
                Spacer()
                
                // 卡片容器
                ZStack {
                    // 背景卡片（下一张）- 只在拖拽时显示
                    if currentIndex < cardManager.cards.count - 1 && abs(dragOffset) > 10 {
                        FlipCardView(card: cardManager.cards[currentIndex + 1], isFlipped: .constant(false))
                            .scaleEffect(0.9)
                            .opacity(0.6)
                            .offset(x: dragOffset * 0.3)
                    }
                    
                    // 当前卡片
                    FlipCardView(card: cardManager.cards[currentIndex], isFlipped: $isCardFlipped)
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
                                    let threshold: CGFloat = 150
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        if abs(value.translation.width) > threshold {
                                            if value.translation.width > 0 && currentIndex > 0 {
                                                // 向右滑动，显示上一张
                                                currentIndex -= 1
                                                isCardFlipped = false // 重置翻面状态
                                                showSwipeHint = false // 切换后隐藏提示文字
                                            } else if value.translation.width < 0 && currentIndex < cardManager.cards.count - 1 {
                                                // 向左滑动，显示下一张
                                                currentIndex += 1
                                                isCardFlipped = false // 重置翻面状态
                                                showSwipeHint = false // 切换后隐藏提示文字
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
                    totalPages: cardManager.cards.count,
                    currentPage: currentIndex
                )
                
                // 滑动提示文字 - 根据状态变量条件显示
                Text(showSwipeHint ? "左右滑动纸张切换题目" : "")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 10)
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

struct FlipCardView: View {
    let card: Card
    @Binding var isFlipped: Bool
    @State private var showDescription = false // 控制描述文本的显示
    @State private var animationTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // 正面
            CardFrontView(cardSide: card.front)
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
                isFlipped.toggle()
                resetDescriptionVisibility() // 重置描述文本的显示状态
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
    @Environment(\.isDescriptionVisible) private var isDescriptionVisible // 从环境中获取描述文本的显示状态
    
    var body: some View {
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
                
                // 标题 - 独立显示
                if let title = cardSide.title {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
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
            Text("点击卡片查看汤底")
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
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
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
            if let image = loadImageFromBundle() {
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
    
    // 从Bundle直接加载图片的辅助方法
    private func loadImageFromBundle() -> UIImage? {
        if let filePath = Bundle.main.path(forResource: "paper", ofType: "jpg") {
            return UIImage(contentsOfFile: filePath)
        }
        return nil
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
}
