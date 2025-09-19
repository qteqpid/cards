import SwiftUI

enum TouchPointName {
    case radio
    case turtle
    case paper
    case music
    case calendar
    case magnifier
}
enum TouchAction {
    case displayCards
    case toggleMusic
    case triggerTurtle
    case introduceSearch
    case showSettings
}

struct TouchPoint {
    let name: TouchPointName
    let image: String
    let positionX: CGFloat
    let positionY: CGFloat
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let action: TouchAction?
}

struct BgMap {
    let bgImage: String
    let touchpoints: [TouchPoint]?
}
