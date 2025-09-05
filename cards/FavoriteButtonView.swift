import SwiftUI

struct FavoriteButtonView: View {
    @ObservedObject var cardManager: CardManager
    @ObservedObject var purchaseManager: InAppPurchaseManager
    @Binding var isCardFlipped: Bool
    @Binding var showEmptyFavoritesAlert: Bool
    @Binding var showPurchaseView: Bool
    
    var body: some View {
        Button(action: {
            // 切换卡片来源
            if cardManager.isFavoriteMode() {
                cardManager.switchCardSource(to: .all)
                // 重置翻面状态
                isCardFlipped = false
            } else {
                // 检查收藏列表是否为空
                if cardManager.favoriteCardIds.isEmpty {
                    // 显示提示框
                    showEmptyFavoritesAlert = true
                } else {
                        // 检查是否需要显示购买弹窗
                    if purchaseManager.shouldShowPurchaseAlert() {
                        showPurchaseView = true
                    } else {
                        cardManager.switchCardSource(to: .favorite)
                        // 重置翻面状态
                        isCardFlipped = false
                    }
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