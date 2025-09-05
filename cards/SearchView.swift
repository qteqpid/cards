import SwiftUI

// 搜索视图组件
struct SearchView: View {
    @ObservedObject var cardManager: CardManager
    // 添加状态变量来跟踪拖动偏移量和当前位置
    @State private var dragOffset = CGSize.zero
    @State private var currentPosition = CGSize.zero
    
    var body: some View {
        // 整体容器，包含turtle图片和搜索框，实现一起拖动
        HStack(spacing: 0) {
            
            // 搜索框 - 增大尺寸并添加放大镜图标
            ZStack {
                HStack {
                    // 左侧放大镜图标
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.gray)
                        .padding(.leading, 12)
                    
                    // 搜索文本输入
                    TextField("搜索卡片...", text: $cardManager.searchText)
                        .padding(.vertical, 16)
                        .padding(.trailing, 12)
                        .foregroundColor(Color.primary)
                }
            }
            .background(Color.white)
            .cornerRadius(15)
            // 添加更明显的边框
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
            )
            // 增强阴影效果使其更立体
            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .frame(width: 220) // 增大搜索框宽度
            .onAppear {
                // 自动聚焦搜索框
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            // turtle图片 - 添加发光效果
            if let turtle = AppConfigs.loadImage(imageName: "turtle", imageType: "png") {
                Image(uiImage: turtle)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    // 添加黄色发光效果
                    .shadow(color: .yellow, radius: 10, x: 0, y: 0)
            }
        }
        .padding(.vertical, 10)
        // 添加拖动功能
        .offset(
            x: currentPosition.width + dragOffset.width,
            y: currentPosition.height + dragOffset.height
        )
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // 在拖动过程中，只更新相对于当前位置的偏移量
                    self.dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    // 拖动结束后，更新当前位置并重置拖动偏移量
                    self.currentPosition.width += gesture.translation.width
                    self.currentPosition.height += gesture.translation.height
                    self.dragOffset = .zero
                }
        )
        .zIndex(1) // 确保搜索框在其他内容之上
    }
}
