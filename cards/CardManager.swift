import Foundation
import SwiftUI

/// 卡片来源枚举
enum CardSource: String {
    case all = "ALL"
    case favorite = "FAVORITE"
}

/// 卡片管理器
/// 负责从JSON文件加载卡片数据和管理收藏列表
class CardManager: ObservableObject {
    @Published var cards: [Card] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 收藏的卡片ID列表
    @Published var favoriteCardIds: [Int] = []
    
    // 卡片来源，默认为ALL
    @Published var cardSource: CardSource = .all
    
    // 本地存储的键名
    private let favoritesKey = "favoriteCardIds"
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadCards()
        loadFavorites()
    }
    
    /// 从JSON文件加载卡片数据
    func loadCards() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json") else {
            errorMessage = "找不到cards.json文件"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let cardData = try decoder.decode(CardData.self, from: data)
            
            // 随机打乱卡片顺序
            cards = cardData.cards.shuffled()
            
            isLoading = false
        } catch {
            errorMessage = "加载卡片数据失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// 重新加载卡片数据
    func reloadCards() {
        loadCards()
    }
    
    /// 添加卡片到收藏列表
    func addToFavorites(cardId: Int) {
        if !favoriteCardIds.contains(cardId) {
            favoriteCardIds.append(cardId)
            saveFavorites()
        }
    }
    
    /// 从收藏列表移除卡片
    func removeFromFavorites(cardId: Int) {
        if let index = favoriteCardIds.firstIndex(of: cardId) {
            favoriteCardIds.remove(at: index)
            saveFavorites()
        }
    }
    
    /// 检查卡片是否已收藏
    func isFavorite(cardId: Int) -> Bool {
        return favoriteCardIds.contains(cardId)
    }
    
    /// 保存收藏列表到本地存储
    private func saveFavorites() {
        userDefaults.set(favoriteCardIds, forKey: favoritesKey)
    }
    
    /// 从本地存储加载收藏列表
    private func loadFavorites() {
        if let savedFavorites = userDefaults.array(forKey: favoritesKey) as? [Int] {
            favoriteCardIds = savedFavorites
        }
    }
    
    /// 获取要显示的卡片列表
    func displayCards() -> [Card] {
        switch cardSource {
        case .all:
            return cards
        case .favorite:
            return cards.filter { favoriteCardIds.contains($0.id) }
        }
    }
    
    /// 判断是否处于收藏模式
    func isFavoriteMode() -> Bool {
        return cardSource == .favorite
    }
    
    /// 切换卡片来源
    /// - Parameter source: 要切换到的卡片来源
    func switchCardSource(to source: CardSource) {
        cardSource = source
    }
}

/// JSON数据结构
struct CardData: Codable {
    let cards: [Card]
}