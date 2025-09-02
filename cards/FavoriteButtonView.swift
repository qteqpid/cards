import SwiftUI

struct FavoriteButtonView: View {
    @ObservedObject var cardManager: CardManager
    @Binding var currentIndex: Int
    @Binding var currentAllIndex: Int
    @Binding var isCardFlipped: Bool
    @Binding var showEmptyFavoritesAlert: Bool
    
    var body: some View {
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
                    .frame(width: AppConfigs.buttonSize, height: AppConfigs.buttonSize)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: AppConfigs.buttonImageSize))
                            .foregroundColor(.red)
                    )
                    .shadow(radius: 5)
            }
        }
        .padding(.top, 20)
        .padding(.leading, 20)
    }
}