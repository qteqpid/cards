import Foundation
import SwiftUI

/// 卡片来源枚举
enum CardSource: String {
    case all = "ALL"
    case favorite = "FAVORITE"
    case search = "SEARCH"
}

/// 卡片管理器
/// 负责从JSON文件加载卡片数据和管理收藏列表
class CardManager: ObservableObject {
    @Published var cards: [Card] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 收藏的卡片ID列表
    @Published var favoriteCardIds: [Int] = []
    
    // 已看过的卡片ID列表（翻了汤底的卡片）
    @Published var viewedCardIds: [Int] = []
    
    // 卡片来源，默认为ALL
    @Published var cardSource: CardSource = .all
    
    // 搜索文本
    @Published var searchText = ""

    @Published var currentIndex = 0
    /// 当前显示的所有卡片索引
    @Published var currentAllIndex = 0
    
    // 本地存储的键名
    private let favoritesKey = "favoriteCardIds"
    private let viewedCardsKey = "viewedCardIds"
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadViewedCards()
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
            
            // Free的cards优先展示
            let topCards = cards.filter { $0.isFreeCard }
            let remainingCards = cards.filter { !$0.isFreeCard }
            cards = Array(topCards) + remainingCards
            
            // 按position调整那些带position值的卡片
            if !cards.isEmpty {
                var reorderedCards = cards
                for (index, card) in cards.enumerated() {
                    if let cardPosition = card.position, cardPosition > 0 {
                        var position = cardPosition
                        if  position > reorderedCards.count {
                            position = reorderedCards.count
                        }
                        // 移除当前位置的卡片
                        reorderedCards.remove(at: index)
                        // 插入到指定位置（position从1开始，所以减1）
                        reorderedCards.insert(card, at: position - 1)
                    }
                }
                cards = reorderedCards
            }
            
            // 将已看过的卡片放到最后面
            let unviewedCards = cards.filter { !viewedCardIds.contains($0.id) }
            let viewedCards = cards.filter { viewedCardIds.contains($0.id) }
            cards = unviewedCards + viewedCards

            // print("加载cards \(cards.count) 个")
            // // 帮忙把每个card的title逐行打印出来
            // for card in cards {
            //     print("   - \(card.front.title) \(card.isFreeCard ? "Free" : "Paid")")
            // }
            
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

    func hasNextIndex() -> Bool {
        return currentIndex < displayCards().count - 1
    }

    func increaseIndex() {
        if hasNextIndex() {
            currentIndex += 1
        }
    }

    func decreaseIndex() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
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
    
    /// 保存已看过卡片列表到本地存储
    private func saveViewedCards() {
        userDefaults.set(viewedCardIds, forKey: viewedCardsKey)
    }
    
    /// 从本地存储加载已看过卡片列表
    private func loadViewedCards() {
        if let savedViewedCards = userDefaults.array(forKey: viewedCardsKey) as? [Int] {
            viewedCardIds = savedViewedCards
        }
    }
    
    /// 标记卡片为已看过
    func markCardAsViewed(cardId: Int) {
        if !viewedCardIds.contains(cardId) {
            viewedCardIds.append(cardId)
            saveViewedCards()
        }
    }
    
    /// 检查卡片是否已看过
    func isCardViewed(cardId: Int) -> Bool {
        return viewedCardIds.contains(cardId)
    }
    
    /// 获取要显示的卡片列表
    func displayCards() -> [Card] {
        switch cardSource {
        case .all:
            return cards
        case .favorite:
            return cards.filter { favoriteCardIds.contains($0.id) }
        case .search:
            if searchText.isEmpty {
                return cards
            } else {
                let lowercasedSearchText = searchText.lowercased()
                return cards.filter {
                    // 搜索卡片的标题、描述
                    ($0.front.title ?? "").lowercased().contains(lowercasedSearchText) ||
                    ($0.front.description ?? "").lowercased().contains(lowercasedSearchText) ||
                    ($0.labels ?? []).contains(lowercasedSearchText) ||
                    ($0.back.description ?? "").lowercased().contains(lowercasedSearchText)
                }
            }
        }
    }
    
    /// 判断是否处于收藏模式
    func isFavoriteMode() -> Bool {
        return cardSource == .favorite
    }

    /// 判断是否处于搜索模式
    func isSearchMode() -> Bool {
        return cardSource == .search
    }
    
    func isAllMode() -> Bool {
        return cardSource == .all
    }
    
    /// 切换卡片来源
    /// - Parameter source: 要切换到的卡片来源
    func switchCardSource(to source: CardSource) {
        let oldSource = cardSource
        cardSource = source
        switch((oldSource, source)) {
            case (.all, .favorite):
                currentAllIndex = currentIndex
                currentIndex = 0
                break
            case (.all, .search):
                currentAllIndex = currentIndex
                currentIndex = 0
                break
            case (.search, .all):
                currentIndex = currentAllIndex
                break
            case (.favorite, .all):
                currentIndex = currentAllIndex
                break
            case (.search, .favorite):
                currentIndex = 0
                break
            case (.favorite, .search):
                currentIndex = 0
                break
            default:
                break
        }
    }
}

/// JSON数据结构
struct CardData: Codable {
    let cards: [Card]
}
