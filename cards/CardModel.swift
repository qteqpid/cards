//
//  CardModel.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI

// 卡片侧面数据模型
struct CardSide: Identifiable, Codable {
    let id = UUID()
    let title: String?
    let subtitle: String?
    let description: String?
    let icon: String?
}

// 卡片数据模型
struct Card: Identifiable, Codable {
    let id = UUID()
    let front: CardSide
    let back: CardSide
}

// 卡片数据已迁移到cards.json文件
// 使用CardManager来加载数据 