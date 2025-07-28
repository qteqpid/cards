//
//  PageIndicatorView.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI

/// 分页指示器视图
/// 用于显示当前页面位置，支持大量数据时的滑动窗口显示
struct PageIndicatorView: View {
    /// 总页面数量
    let totalPages: Int
    /// 当前页面索引
    let currentPage: Int
    /// 最大显示的指示器数量
    let maxIndicators: Int
    /// 指示器颜色
    let activeColor: Color
    /// 指示器间距
    let spacing: CGFloat
    /// 指示器大小
    let size: CGFloat
    /// 激活状态的缩放比例
    let activeScale: CGFloat
    
    /// 初始化方法
    /// - Parameters:
    ///   - totalPages: 总页面数量
    ///   - currentPage: 当前页面索引
    ///   - maxIndicators: 最大显示的指示器数量，默认为8
    ///   - activeColor: 激活状态的颜色，默认为应用背景色
    ///   - spacing: 指示器间距，默认为8
    ///   - size: 指示器大小，默认为8
    ///   - activeScale: 激活状态的缩放比例，默认为1.2
    init(
        totalPages: Int,
        currentPage: Int,
        maxIndicators: Int = 8,
        activeColor: Color = AppConfigs.appBackgroundColor,
        spacing: CGFloat = 8,
        size: CGFloat = 8,
        activeScale: CGFloat = 1.2
    ) {
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.maxIndicators = maxIndicators
        self.activeColor = activeColor
        self.spacing = spacing
        self.size = size
        self.activeScale = activeScale
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            if totalPages <= maxIndicators {
                // 页面数量少于等于最大指示器数量时，显示所有指示器
                ForEach(0..<totalPages, id: \.self) { index in
                    indicatorCircle(for: index)
                }
            } else {
                // 页面数量超过最大指示器数量时，使用滑动窗口显示
                let windowSize = maxIndicators
                let halfWindow = windowSize / 2
                
                // 计算显示的起始索引
                let startIndex = max(0, min(currentPage - halfWindow, totalPages - windowSize))
                let endIndex = startIndex + windowSize
                
                ForEach(startIndex..<endIndex, id: \.self) { index in
                    indicatorCircle(for: index)
                }
            }
        }
        .padding(.bottom, 30)
    }
    
    /// 创建单个指示器圆点
    /// - Parameter index: 页面索引
    /// - Returns: 指示器圆点视图
    @ViewBuilder
    private func indicatorCircle(for index: Int) -> some View {
        Circle()
            .fill(index == currentPage ? activeColor : .gray.opacity(0.3))
            .frame(width: size, height: size)
            .scaleEffect(index == currentPage ? activeScale : 1.0)
            .animation(.spring(response: 0.3), value: currentPage)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 预览：少量页面
        PageIndicatorView(totalPages: 5, currentPage: 2)
        
        // 预览：大量页面
        PageIndicatorView(totalPages: 16, currentPage: 8)
        
        // 预览：自定义样式
        PageIndicatorView(
            totalPages: 10,
            currentPage: 5,
            maxIndicators: 6,
            activeColor: .red,
            spacing: 12,
            size: 10,
            activeScale: 1.5
        )
    }
    .padding()
} 