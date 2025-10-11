import SwiftUI

// 应用标题视图组件
struct AppTitleView: View {
    @ObservedObject var cardManager: CardManager
    
    var body: some View {

        
            
            ZStack {
                if (cardManager.isSearchMode()) {
                    // 搜索框 - 增大尺寸并添加放大镜图标
                    ZStack {
                        HStack {
                            // 左侧放大镜图标
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.gray)
                                .padding(.leading, 8)
                            
                            // 搜索文本输入
                            TextField("搜索海龟汤...", text: $cardManager.searchText)
                                .padding(.vertical, 8)
                                .padding(.trailing, 12)
                                .foregroundColor(Color.primary)
                            
                            Image(systemName: "xmark.circle")
                                .foregroundColor(Color.pink)
                                .padding(.trailing, 8)
                                .onTapGesture() {
                                    cardManager.switchCardSource(to: .all)
                                    cardManager.searchText = ""
                                }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    // 添加更明显的边框
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                    )
                    // 增强阴影效果使其更立体
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .frame(width: AppConfigs.screenWidth / 2 - 40)
                    .onAppear {
                        // 自动聚焦搜索框
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                } else {
                    
                    if let img = AppConfigs.loadImage(name: "magnifier_icon.png") {
                        HStack{
                            Spacer()
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .opacity(0.7)
                        }
                        .padding(.top, 5)
                        .padding(.trailing, 30)
                    }
                    
                    Text(cardManager.isFavoriteMode() ? "我的私房汤" : AppConfigs.appTitle)
                        .font(.system(size: AppConfigs.appTitleSize, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
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
                        .onTapGesture(count: 2) {
                            if (cardManager.isAllMode()) {
                                cardManager.searchText = ""
                                cardManager.switchCardSource(to: .search)
                            }
                        }
                        .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 6)
                }
                
            }
            .frame(width: AppConfigs.screenWidth / 2, height: 50)
        
    }
}
