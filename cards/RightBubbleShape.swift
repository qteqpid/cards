import SwiftUI

struct RightBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 16
        let tipWidth: CGFloat = 12
        let tipHeight: CGFloat = 14
        // 起点：右上角
        path.move(to: CGPoint(x: rect.maxX - tipWidth - radius, y: rect.minY))
        // 顶部直线
        path.addLine(to: CGPoint(x: radius, y: rect.minY))
        // 左上角圆角
        path.addArc(center: CGPoint(x: radius, y: rect.minY + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(180), clockwise: true)
        // 左侧直线
        path.addLine(to: CGPoint(x: 0, y: rect.maxY - radius))
        // 左下角圆角
        path.addArc(center: CGPoint(x: radius, y: rect.maxY - radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        // 底部直线
        path.addLine(to: CGPoint(x: rect.maxX - tipWidth - radius, y: rect.maxY))
        // 右下角圆角
        path.addArc(center: CGPoint(x: rect.maxX - tipWidth - radius, y: rect.maxY - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        // 右侧直线到三角形底部
        path.addLine(to: CGPoint(x: rect.maxX - tipWidth, y: rect.minY + rect.height/2 + tipHeight/2))
        // 三角形
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height/2))
        path.addLine(to: CGPoint(x: rect.maxX - tipWidth, y: rect.minY + rect.height/2 - tipHeight/2))
        // 右侧直线到右上角圆角
        path.addLine(to: CGPoint(x: rect.maxX - tipWidth, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.maxX - tipWidth - radius, y: rect.minY + radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(270), clockwise: true)
        path.closeSubpath()
        return path
    }
}