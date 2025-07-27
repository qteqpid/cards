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
    
    var body: some View {
        ZStack {
            // 动态渐变背景
            LinearGradient(
                colors: [
                    AppConfigs.appBackgroundColor.opacity(0.3),
                    AppConfigs.appBackgroundColor.opacity(0.1),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("重新加载") {
                        cardManager.reloadCards()
                    }
                    .foregroundColor(AppConfigs.appBackgroundColor)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppConfigs.appBackgroundColor, lineWidth: 2)
                    )
                }
            }
            
            // 正常内容
            else if !cardManager.cards.isEmpty {
            
            VStack {
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
                                            } else if value.translation.width < 0 && currentIndex < cardManager.cards.count - 1 {
                                                // 向左滑动，显示下一张
                                                currentIndex += 1
                                                isCardFlipped = false // 重置翻面状态
                                            }
                                        }
                                        dragOffset = 0
                                    }
                                }
                        )
                }
                
                Spacer()
                
                // 指示器
                HStack(spacing: 8) {
                    ForEach(0..<cardManager.cards.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? AppConfigs.appBackgroundColor : .gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .padding(.bottom, 30)
            }
            }
        }
    }
}

struct FlipCardView: View {
    let card: Card
    @Binding var isFlipped: Bool
    
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
            }
        }
    }
}

struct CardFrontView: View {
    let cardSide: CardSide
    
    var body: some View {
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
            
            // 副标题 - 独立显示
            if let subtitle = cardSide.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppConfigs.appBackgroundColor)
                    .fontWeight(.medium)
            }
            
            // 描述 - 只在有描述时显示
            if let description = cardSide.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(30)
        .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.white)
                .shadow(color: AppConfigs.appBackgroundColor.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(AppConfigs.appBackgroundColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CardBackView: View {
    let cardSide: CardSide
    
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
            
            // 背面副标题 - 独立显示
            if let subtitle = cardSide.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppConfigs.appBackgroundColor)
                    .fontWeight(.medium)
            }
            
            // 背面描述 - 只在有描述时显示
            if let description = cardSide.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Spacer()
            
            // 提示文字
            Text("点击卡片翻回正面")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 0)
        }
        .padding(30)
        .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.white)
                .shadow(color: AppConfigs.appBackgroundColor.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(AppConfigs.appBackgroundColor.opacity(0.2), lineWidth: 1)
        )
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
