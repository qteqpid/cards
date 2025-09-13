import SwiftUI


enum TouchAction {
    case displayCards
    case toggleMusic
    case triggerTurtle
}

struct TouchPoint {
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