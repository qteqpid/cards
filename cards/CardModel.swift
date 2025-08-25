//
//  CardModel.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI

// 卡片侧面数据模型
struct CardSide: Codable {
    let title: String?
    let description: String?
    let icon: String?
}

// 卡片数据模型
struct Card: Identifiable, Codable {
    // 从JSON加载的整数ID，实现Identifiable协议
    let id: Int
    
    let front: CardSide
    let back: CardSide
}

// 卡片数据已迁移到cards.json文件
// 使用CardManager来加载数据