import Foundation
import SwiftUI

/// 卡片管理器
/// 负责从JSON文件加载卡片数据
class CardManager: ObservableObject {
    @Published var cards: [Card] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadCards()
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
            cards = cardData.cards
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
}

/// JSON数据结构
struct CardData: Codable {
    let cards: [Card]
} 