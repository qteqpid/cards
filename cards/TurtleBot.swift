
import SwiftUI
import Combine
import Foundation

enum BotState {
    case isWaiting
    case isThinking
    case isSpeaking
}

enum Scenario {
    case none
    case notification
    case challenge
}

class TurtleBot: ObservableObject {
    // 单例实例
    static let shared = TurtleBot()
    
    @Published var isVisible = false
    @Published var position = CGPoint(x: AppConfigs.screenWidth * 0.5, y: AppConfigs.screenHeight * 0.4)
    @Published var botState = BotState.isWaiting
    @Published var userInput = "" // 存储识别到的文本
    @Published var fullResponseText = "" // 存储完整的回复文本
    @Published var displayedText = "" // 用于打字机效果的显示文本
    private var scenario = Scenario.none
    private static let name = "龟哥"
    private var typingTimer: Timer? // 存储定时器实例
    
    init() {}
    
    func isInScenarioOf(scenario: Scenario) -> Bool {
        return isVisible && self.scenario == scenario
    }
    
    func switchToScenario(scenario: Scenario) {
        self.scenario = scenario
        isVisible = true
    }

    func hide() {
        isVisible = false
        scenario = .none
        userInput = ""
        fullResponseText = ""
        displayedText = ""
    }
    
    func getTurtleIcon() -> String {
        switch scenario {
        case .none:
            return "turtle.png"
        case .notification:
            return "turtle_doctor_icon.png"
        case .challenge:
            return "turtle_detective_icon.png"
        }
    }
    
    func thinkAndReply(_ userInput: String) {
        self.switchState(state: .isThinking)
        self.displayedText = ""
        // 思考并获取回复
        let response = self.think(userInput)
        // 添加延迟，在回答前停几秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 播放回复
            self.speak(response)
        }
    }
    
    func speak(_ response: String) {
        // 先停止之前的定时器（如果有）
        typingTimer?.invalidate()

        self.fullResponseText = response
        // 将状态设置为回答，显示回答气泡
        self.displayedText = "" // 清空显示文本，准备打字机效果
        
        // 实现打字机效果 - 按标点符号分词
        let segments = getSegments(response: response)
        var currentIndex = 0
        // 创建新定时器
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
            [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return 
            }
            
            if currentIndex < segments.count {
                // 添加当前分句到显示文本
                self.displayedText += segments[currentIndex]
                currentIndex += 1
            } else {
                // 所有分句都显示完了，停止定时器
                timer.invalidate()
                self.typingTimer = nil // 清除引用
            }
        }
        
        switchState(state: .isWaiting)
    }

    private func think(_ userInput: String) -> String {
        switchState(state: .isThinking)
        if let userInput = self.userInput as String? {
            // 调用SkillFactory处理文本并获取响应
            return userInput
        } else {
            return "我没听清你说的话"
        }
    }

    private func switchState(state: BotState) {
        self.botState = state
        //print("切换状态为：\(state)")
    }

    private func getSegments(response: String) -> [String] {
        // 实现打字机效果 - 按标点符号分词
        // 分割正则表达式：匹配中文和英文的标点符号
        let pattern = "([。！？,，.!?；；;:：])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        // 将文本按标点符号分割，保留标点符号
        var segments: [String] = []
        if let regex = regex {
            let matches = regex.matches(in: response, options: [], range: NSRange(location: 0, length: response.utf16.count))
            
            if matches.isEmpty {
                // 如果没有匹配到标点符号，就整个作为一段
                segments = [response]
            } else {
                var lastRangeEnd = 0
                
                for match in matches {
                    let matchRange = match.range(at: 0)
                    let matchStart = matchRange.location
                    
                    // 添加标点符号前的文本
                    if matchStart > lastRangeEnd {
                        let textRange = NSRange(location: lastRangeEnd, length: matchStart - lastRangeEnd)
                        if let substring = Range(textRange, in: response) {
                            if let sep = Range(matchRange, in: response) { // 句子+标点
                                segments.append(String(response[substring])+String(response[sep]))
                            } else {
                                segments.append(String(response[substring]))
                            }     
                        }
                    }
                    lastRangeEnd = matchStart + matchRange.length
                }
                
                // 添加最后一个标点符号后的文本（如果有的话）
                if lastRangeEnd < response.utf16.count {
                    let textRange = NSRange(location: lastRangeEnd, length: response.utf16.count - lastRangeEnd)
                    if let substring = Range(textRange, in: response) {
                        segments.append(String(response[substring]))
                    }
                }
            }
        } else {
            // 如果正则表达式创建失败，就整个作为一段
            segments = [response]
        }
        return segments
    }

    private let doctorKnowledges = [
        "你好！我是\(TurtleBot.name)，欢迎来到我的房间。这个地图上有很多隐藏的机关，找到并点击它们，开始探索吧!\n对了，帮忙双击下我的龟脑袋，我先去休息了...",
        "每日小提醒：海龟汤作为一种融合推理与脑洞的社交游戏风靡全球。但小学生对死亡话题的天然好奇，通过海龟汤转化为推理乐趣，需警惕部分谜题中\"尸体\"、\"虐杀\"等元素可能带来的心理冲击。\n如果你年龄尚小，请慎重玩汤哦!",
        "每日小知识：海龟汤游戏起源于日本，英文原名是\"Lateral Thinking Puzzle\"（水平思考谜题），后来在中国被翻译成了更易记的\"海龟汤\"呢！",
        "每日小知识：玩海龟汤的核心是\"水平思考\"，由英国心理学家爱德华・德・波诺（Edward de Bono）于 1967 年首次提出，不能只用常规逻辑哦！要学会从不同角度想问题，才能揭开谜底。",
        "每日小知识：1992年，保罗・斯隆（Paul Sloane）在《水平思维谜题》一书中将水平思考法具象化为\"情境猜谜\"游戏，即由出题者给出一个不完整事件，玩家通过\"是/否\"提问还原真相。这类谜题最初在欧美以\"Situation Puzzle\" 或 \"Lateral Thinking Puzzle\" 为名流传，但尚未形成统一的文化符号。",
        "每日小知识：海龟汤可以划分为\"清汤\"（无血腥）、\"红汤\"（含尸体）、\"黑汤\"（重口味恐怖）。",
        "每日小知识：本格海龟汤以现实逻辑为绝对核心，谜题的汤底必须符合物理规则、人类行为逻辑或常识。玩家通过提问逐步排除不可能的情况，最终通过严谨的因果关系揭示真相。\n变格海龟汤以异常设定或氛围冲击为核心，允许超自然现象、心理扭曲或猎奇元素的存在。谜题的解答可能突破现实逻辑，重点在于制造反转的惊悚感。"
    ]
    private var knowledgeIndex = 0
    func getDoctorKnowledge() -> String {
        if !doctorKnowledges.isEmpty {
            if (knowledgeIndex == 0) {
                knowledgeIndex+=1
                return doctorKnowledges[0]
            } else {
                knowledgeIndex = knowledgeIndex % (doctorKnowledges.count - 1)  + 1
                return doctorKnowledges[knowledgeIndex]
            }
        }
        return "我是\(TurtleBot.name)，随时为你解答问题！"
    }
    
}

// 为String添加扩展，实现正则表达式匹配功能
extension String {
    func matches(pattern: String) -> Bool {
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self)
    }
}





// 龟龟视图组件
struct TurtleView: View {
    @ObservedObject var cardManager: CardManager
    // 添加状态变量来跟踪拖动偏移量和当前位置
    @State private var dragOffset = CGSize.zero
    @State private var currentPosition = CGSize.zero
    
    var body: some View {
        // 整体容器，包含turtle图片和搜索框，实现一起拖动
        HStack(spacing: 0) {
            if (TurtleBot.shared.isInScenarioOf(scenario: Scenario.notification)) {
                TurtleNotificationView()
            } else {
                TurtleInputView(cardManager: cardManager)
            }
            
            // turtle图片 - 添加发光效果
            if let turtle = AppConfigs.loadImage(name: TurtleBot.shared.getTurtleIcon()) {
                Image(uiImage: turtle)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    // 添加黄色发光效果
                    .shadow(color: .yellow, radius: 10, x: 0, y: 0)
                    .onTapGesture(count: 2) {
                        TurtleBot.shared.hide()
                    }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        // 添加拖动功能
        .offset(
            x: currentPosition.width + dragOffset.width,
            y: currentPosition.height + dragOffset.height
        )
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // 在拖动过程中，只更新相对于当前位置的偏移量
                    self.dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    // 拖动结束后，更新当前位置并重置拖动偏移量
                    self.currentPosition.width += gesture.translation.width
                    self.currentPosition.height += gesture.translation.height
                    self.dragOffset = .zero
                }
        )
        .zIndex(100) // 确保搜索框在其他内容之上
        .position(TurtleBot.shared.position) // 定位到屏幕中下位置
    }
}


struct TurtleInputView: View {
    @ObservedObject var cardManager: CardManager
    
    var body: some View {
        // 搜索框 - 增大尺寸并添加放大镜图标
        ZStack {
            HStack {
                // 左侧放大镜图标
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.gray)
                    .padding(.leading, 12)
                
                // 搜索文本输入
                TextField("搜索海龟汤...", text: $cardManager.searchText)
                    .padding(.vertical, 16)
                    .padding(.trailing, 12)
                    .foregroundColor(Color.primary)
            }
        }
        .background(Color.white)
        .cornerRadius(15)
        // 添加更明显的边框
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
        )
        // 增强阴影效果使其更立体
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .frame(width: 220) // 增大搜索框宽度
        .onAppear {
            // 自动聚焦搜索框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

struct TurtleNotificationView: View {
    @ObservedObject private var turtleBot = TurtleBot.shared

    var body: some View {
        VStack(alignment: .trailing) {
            Text(turtleBot.displayedText.isEmpty ? "..." : turtleBot.displayedText)
                .font(.system(size: 20))
                .foregroundColor(AppConfigs.fontBlackColor)
                .padding(.trailing, 28)
                .padding(.vertical, 12)
                .padding(.leading, 16)
                .fixedSize(horizontal: false, vertical: true)
        }
        .background(
            RightBubbleShape()
                .fill(Color.white.opacity(0.8))
        )
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        .frame(maxWidth: AppConfigs.screenWidth * 0.8, alignment: .trailing) // 限制最大宽度为屏幕宽度的80%
        .padding(.trailing, 0)
    }
}
