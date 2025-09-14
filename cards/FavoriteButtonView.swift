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
                if let mapIcon = AppConfigs.loadImage(name: "heart_icon.png") {
                    Image(uiImage: mapIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: AppConfigs.buttonSize, height: AppConfigs.buttonSize)
                        .shadow(radius: 5)
                }
            }
        }
        .padding(.leading, 20)
    }
}
