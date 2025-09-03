//  LabelsView.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI

struct LabelsView: View {
    let labels: [String]
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(labels, id: \.self) {
                label in
                Text(label)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                    .background(colorForLabel(label))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 2]))
                                    )
                                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 根据label内容返回不同的背景颜色
    private func colorForLabel(_ label: String) -> Color {
        let colors: [String: Color] = [
            "红汤": Color.red.opacity(0.2),
            "清汤": Color.green.opacity(0.2),
            "变格": Color.white.opacity(0.3),
            "本格": Color.gray.opacity(0.2)
        ]
        
        if let color = colors[label] {
            return color
        } else {
            return Color.yellow.opacity(0.2)
        }
    }
}