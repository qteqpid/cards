import SwiftUI

struct FlipCardView: View {
    let card: Card
    @Binding var isFlipped: Bool
    @State private var showDescription = false // 控制描述文本的显示
    @State private var animationTimer: Timer? = nil
    @ObservedObject var purchaseManager: InAppPurchaseManager
    @Binding var showPurchaseView: Bool
    
    var body: some View {
        ZStack {
            // 正面
            CardFrontView(cardSide: card.front, cardId: card.id, author: card.author, labels: card.labels)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 0 : 1)
            
            // 背面
            CardBackView(cardSide: card.back, cardId: card.id)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.8)) {                
                // 点击卡片时检查是否需要显示购买提醒
                if purchaseManager.shouldShowPurchaseAlert() {
                    showPurchaseView = true
                } else {
                    purchaseManager.increaseUseTimes()
                    isFlipped.toggle()
                    resetDescriptionVisibility() // 重置描述文本的显示状态
                }
            }
        }
        .onAppear {
            resetDescriptionVisibility() // 卡片出现时重置描述文本的显示状态
        }
        .environment(\.isDescriptionVisible, showDescription)
    }
    
    // 重置描述文本的显示状态，1秒后显示
    private func resetDescriptionVisibility() {
        showDescription = false
        
        // 移除之前的计时器
        animationTimer?.invalidate()
        
        // 设置1秒后显示描述文本
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
            _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                showDescription = true
            }
        }
    }
}

struct CardFrontView: View {
    let cardSide: CardSide
    let cardId: Int // 卡片ID
    let author: String?
    let labels: [String]? // 标签数组
    @Environment(\.isDescriptionVisible) private var isDescriptionVisible // 从环境中获取描述文本的显示状态
    @State private var showHeartAnimation = false // 控制爱心动画的显示状态
    @State private var heartScale: CGFloat = 0 // 控制爱心的缩放比例
    @State private var isAddingToFavorites = true // 跟踪当前操作是收藏还是取消收藏
    @EnvironmentObject private var cardManager: CardManager // 使用环境对象访问CardManager
    


    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()
                
                // 内容区域
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
                    
                    // 标题
                    if let title = cardSide.title {
                        VStack {
                            Text(title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            if let author {
                                Text("by "+author)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .opacity(0.8)
                            }
                        }
                    }
                    
                    // 标签 - 只在有标签时显示
                    if let labels = labels, !labels.isEmpty {
                        LabelsView(labels: labels)
                            .padding(.vertical, -10) // 减小标签和描述之间的间距
                            .padding(.horizontal, 14)
                            .opacity(isDescriptionVisible ? 1 : 0) // 根据状态控制透明度
                    }
                    
                    // 描述 - 只在有描述时显示
                    if let description = cardSide.description {
                        ScrollView {
                            Text(description)
                                .font(.title2)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .opacity(isDescriptionVisible ? 1 : 0) // 根据状态控制透明度
                                .scaleEffect(isDescriptionVisible ? 1 : 0.95) // 根据状态控制缩放
                        }
                        .layoutPriority(1)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 10)
                    }
                }
                
                Spacer()
                // 提示文字
                Text("点击纸张查看汤底")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.bottom, 0)
            }
            .padding(30)
            .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
            .background(CardBackgroundView(cardId: cardId))
            
            // 在收藏模式下显示浮动的收藏图标，位于卡片左上角
            if cardManager.isFavoriteMode() {
                if let favoriteImage = AppConfigs.loadImage(name: "favorite.png") {
                    Image(uiImage: favoriteImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .position(x: 70, y: 70)
                        .opacity(0.6)
                        .transition(.scale)
                }
            } else {
                if let author, let originalImage = AppConfigs.loadImage(name: "original.png") {
                    Image(uiImage: originalImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .position(x: 70, y: 70)
                        .opacity(0.6)
                        .transition(.scale)
                }
            }
        }
        .onTapGesture(count: 2) { // 添加双击手势
            withAnimation {
                showHeartAnimation = true
                
                // 将卡片ID添加到收藏列表中（如果尚未收藏）
                if !cardManager.isFavorite(cardId: cardId) {
                    isAddingToFavorites = true
                    cardManager.addToFavorites(cardId: cardId)
                } else {
                    isAddingToFavorites = false
                    // 先显示灰色爱心再切换index
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        cardManager.removeFromFavorites(cardId: cardId)
                        if (cardManager.isFavoriteMode()) {
                            cardManager.decreaseIndex()
                        }
                    }
                    
                }
                    
                    // 第一阶段：从0放大到1.2
                withAnimation(Animation.easeOut(duration: 0.5)) {
                    heartScale = 1.2
                }
                
                // 第二阶段：从1.2稍微缩小到1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(Animation.easeIn(duration: 0.3)) {
                        heartScale = 1.0
                    }
                }
                
                // 0.5秒后隐藏爱心
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(Animation.easeOut(duration: 0.3)) {
                        heartScale = 0
                        showHeartAnimation = false
                    }
                }
            }
        }
        .overlay( // 添加爱心动画覆盖层
            ZStack {
                if showHeartAnimation {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(isAddingToFavorites ? Color.red : Color.gray)
                        //.opacity(0.8)
                        .scaleEffect(heartScale)
                }
            }
        )
    }
    
    
}

struct CardBackView: View {
    let cardSide: CardSide
    let cardId: Int
    // 移除环境变量引用，不再使用延迟显示效果
    
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
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            
            
            // 背面描述 - 只在有描述时显示
            if let description = cardSide.description {
                ScrollView {
                    Text(description)
                        .font(.title2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                }
                .layoutPriority(1)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 10)
            }
            
            // 提示文字
            Text("点击纸张翻回汤面")
                .font(.caption)
                .foregroundColor(.primary)
                .padding(.bottom, 0)
        }
        .padding(30)
        .frame(width: AppConfigs.cardWidth, height: AppConfigs.cardHeight)
        .background(CardBackgroundView(cardId: cardId))
    }
}

// 创建共用的卡片背景视图组件
struct CardBackgroundView: View {
    let cardId: Int
    @EnvironmentObject private var cardManager: CardManager // 使用环境对象访问CardManager
    
    var body: some View {
        ZStack {
            // 通过Bundle文件路径加载图片
            if let image = AppConfigs.loadImage(name: "paper.png") {
                Image(uiImage: image)
                    
                    .resizable()
                    .scaledToFill()
                    .shadow(color: cardManager.isFavorite(cardId: cardId) ? .yellow : .clear, radius: 2, x: 0, y: 0)
            } else {
                // 如果加载失败，显示一个备用的米色背景
                Color(red: 0.94, green: 0.91, blue: 0.81)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
        }.padding(10)
    }
}
