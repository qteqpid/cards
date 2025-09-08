//
//  CardView.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/9/8.
//

import SwiftUI

struct CardView: View {
    let cardManager: CardManager
    let purchaseManager: InAppPurchaseManager
    @Binding var currentIndex: Int
    @Binding var dragOffset: CGFloat
    @Binding var isDragging: Bool
    @Binding var isCardFlipped: Bool
    @Binding var showPurchaseView: Bool
    @Binding var showSwipeHint: Bool
    
    var body: some View {
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
    }
}