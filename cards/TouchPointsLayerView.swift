//
//  TouchPointsLayerView.swift
//  cards
//
//  Created by [Author] on [Date].
//

import SwiftUI

struct TouchPointsLayerView: View {
    @ObservedObject private var musicPlayer = MusicPlayer.shared
    @Binding var showScrollView: Bool
    @Binding var showRatingAlert: Bool // 控制是否显示评分邀请弹窗
    @Binding var showSettings: Bool
    
    // 存储每个touchpoint的临时位置
    @State private var dragPositions: [String: CGPoint] = [:]
    
    var body: some View {
        ZStack {
            // 展示AppConfigs.currentBgMap里的touchpoints数据
            if let touchpoints = AppConfigs.currentBgMap.touchpoints {
                ForEach(touchpoints, id: \.image) {
                    touchpoint in
               
                    if (shouldShow(touchpoint: touchpoint)) {
                        if let touchImage = AppConfigs.loadImage(name: touchpoint.image) {
                            // 计算实际位置和尺寸
                            self.createTouchPointView(
                                touchpoint: touchpoint,
                                touchImage: touchImage
                            )
                        }
                    }
                }
            }
        }
        
        .ignoresSafeArea()
    }
    
    // 创建touchpoint视图的辅助方法，避免在ViewBuilder中进行复杂计算
    private func createTouchPointView(
        touchpoint: TouchPoint,
        touchImage: UIImage
    ) -> some View {
        // 直接使用屏幕的长宽进行计算
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // 计算实际位置和尺寸，传入图片原始尺寸以计算正确的缩放因子
        let (actualPosition, actualWidth, actualHeight, dragStartPosition) = calculatePositionAndSize(
            touchpoint: touchpoint,
            touchImage: touchImage,
            containerWidth: screenWidth,
            containerHeight: screenHeight
        )
        
        return Group {
            Image(uiImage: touchImage)
                .resizable()
                .scaledToFit()
                .frame(width: actualWidth, height: actualHeight)
                // 为music_symbol.png图片添加一圈白光效果
                .shadow(color: touchpoint.name == TouchPointName.music ? .white : .yellow, radius: 5, x: 0, y: 0)
                .position(actualPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 拖动过程中更新位置
                            self.dragPositions[touchpoint.image] = CGPoint(
                                x: dragStartPosition.x + value.translation.width,
                                y: dragStartPosition.y + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            // 拖动结束后回到原始位置
                            self.dragPositions[touchpoint.image] = nil
                        }
                )
                .onTapGesture {
                    if let action = touchpoint.action {
                        switch action {
                            case .displayCards:
                                showScrollView = true
                            case .toggleMusic:
                                self.musicPlayer.togglePlayback()
                            case .triggerTurtle:
                                if (TurtleBot.shared.isVisible) {
                                    TurtleBot.shared.hide()
                                } else {
                                    TurtleBot.shared.switchToScenario(scenario: Scenario.notification)
                                    TurtleBot.shared.speak(TurtleBot.shared.getDoctorKnowledge())
                                    AppRatingManager.shared.incrementButtonTapCount()
                                    if (AppRatingManager.shared.shouldShowRatingAlert()) {
                                        showRatingAlert = true
                                    }
                                }
                            case .introduceSearch:
                                TurtleBot.shared.switchToScenario(scenario: Scenario.notification)
                                TurtleBot.shared.speak("双击主页顶部大标题就可以搜索海龟汤，快去试试吧！\n对了，帮忙双击下我的龟脑袋，我先去休息了")
                                AppRatingManager.shared.incrementButtonTapCount()
                                if (AppRatingManager.shared.shouldShowRatingAlert()) {
                                    showRatingAlert = true
                                }
                            case .showSettings:
                                showSettings = true
                        }
                        
                    }
                }
            
            if dragPositions[touchpoint.image] != nil {
                // 在图片下方显示坐标值
                Text(String(format: "X: %.1f, Y: %.1f", (actualPosition.x - screenWidth/2), (actualPosition.y - screenHeight/2)))
                    .foregroundColor(.black)
                    .background(Color.white.opacity(0.8))
                    .padding(4)
                    .font(.caption)
                    .position(
                        x: actualPosition.x,
                        y: actualPosition.y - 40
                    )
            }

        }
    }
    
    // 计算位置和尺寸的辅助方法
    private func calculatePositionAndSize(
        touchpoint: TouchPoint,
        touchImage: UIImage,
        containerWidth: CGFloat,
        containerHeight: CGFloat
    ) -> (CGPoint, CGFloat, CGFloat, CGPoint) {
        // 计算屏幕中心点坐标
        let centerX = containerWidth / 2.0
        let centerY = containerHeight / 2.0

        var z = 1.0
        if (containerWidth / containerHeight < 9/16) { // 瘦长型以高为准
            z = containerHeight / AppConfigs.heightToCompared
        } else {
            z = containerWidth / AppConfigs.widthToCompared
        }
        
        // 根据用户要求计算实际位置：中心点坐标 + z * positionX/Y
        let actualPosition = self.dragPositions[touchpoint.image] ?? CGPoint(
            x: centerX + z * touchpoint.positionX,
            y: centerY + z * touchpoint.positionY
        )
        
        // 计算拖拽起始点
        let dragStartPosition = CGPoint(
            x: centerX + z * touchpoint.positionX,
            y: centerY + z * touchpoint.positionY
        )
        
        // 计算缩放后的图片尺寸
        let scaledWidth = touchpoint.frameWidth * z
        let scaledHeight = touchpoint.frameHeight * z
        
        return (
            actualPosition,
            scaledWidth,
            scaledHeight,
            dragStartPosition
        )
    }

    private func shouldShow (
        touchpoint: TouchPoint
    ) -> Bool {
        if (touchpoint.name == TouchPointName.music && !musicPlayer.isPlaying) {
            return false
        }
        return true
    }
}
