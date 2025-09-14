import SwiftUI

// 应用标题视图组件
struct AppTitleView: View {
    @ObservedObject var purchaseManager: InAppPurchaseManager
    @ObservedObject var cardManager: CardManager
    
    var body: some View {
        Text(AppConfigs.appTitle)
            .font(.system(size: AppConfigs.appTitleSize, weight: .black, design: .rounded))
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
            .onTapGesture(count: 2) {
                if cardManager.isAllMode() {
                    withAnimation {
                        cardManager.searchText = ""
                        cardManager.switchCardSource(to: .search)
                    }
                } else if cardManager.isSearchMode() {
                    withAnimation {
                        cardManager.switchCardSource(to: .all)
                        cardManager.searchText = ""
                    }
                }
            }
            .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 6)
    }
}
