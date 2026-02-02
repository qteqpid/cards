
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

// 定义消息结构体，用于存储用户输入和回复
struct Message: Identifiable, Codable {
    let id = UUID()
    let timestamp = Date()
    let isUser: Bool
    let content: String
    let userInputForJudge: String?
    
    // 初始化方法，为userInputForJudge提供默认值
    init(isUser: Bool, content: String, userInputForJudge: String? = nil) {
        self.isUser = isUser
        self.content = content
        self.userInputForJudge = userInputForJudge
    }
}

class TurtleBot: ObservableObject {
    // 单例实例
    static let shared = TurtleBot()
    
    @Published var isVisible = false
    @Published var botState = BotState.isWaiting
    @Published var userInput = "" // 存储识别到的文本
    @Published var fullResponseText = "" // 存储完整的回复文本
    @Published var displayedText = "" // 用于打字机效果的显示文本
    @Published var conversationHistory: [Message] = [] // 存储对话历史记录
    private var scenario = Scenario.none
    private static let name = "龟博士"
    private var typingTimer: Timer? // 存储定时器实例
    private let judgeBot = JudgeBot(apiKey: "265138820d1c4bd2909506540624b718.LroRUoYiWbojTMWG") // 初始化JudgeBot实例
    private var questionCount = 0 // 记录针对当前卡片的询问次数
    private var correctGuessCount = 0 // 记录猜对的次数
    private var isSuccess = false // 记录是否已经完全猜出汤底
    
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
    
    func resetConversationHistory(_ card: Card? = nil) {
        if let card = card {
            // 清空对话历史
            conversationHistory.removeAll()
            // 重置询问次数和猜对次数
            questionCount = 0
            correctGuessCount = 0
            isSuccess = false
            // 如果有卡片信息，更新默认消息

            var instruction = ""
            if !UserTracker.shared.hasShownInstruction {
                instruction = "你有10次机会可以提问，我会根据汤底回答\"是/不是/不相关\"。\n"
                UserTracker.shared.hasShownInstruction = true
            }

            let defaultMessage = Message(isUser: false, content: "hi，我是龟探长。\(instruction)本次海龟汤题目：\(card.front.title ?? "")，请开始提问吧。实在想不出来也可以问我要提示哦")
            conversationHistory.append(defaultMessage)
        }
    }

    func getTurtlePosition() -> CGPoint {
        switch scenario {
        case .none:
            return CGPoint(x: AppConfigs.screenWidth * 0.5, y: AppConfigs.screenHeight * 0.4)
        case .notification:
            return CGPoint(x: AppConfigs.screenWidth * 0.5, y: AppConfigs.screenHeight * 0.4)
        case .challenge:
            return CGPoint(x: AppConfigs.screenWidth * 0.5, y: AppConfigs.screenHeight * 0.1)
        }
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

    func judge(_ userInput: String, card: Card) {
        // 更新self.userInput为最新的用户输入
        self.userInput = userInput
        
        // 添加用户输入到历史记录
        let userMessage = Message(isUser: true, content: userInput)
        conversationHistory.append(userMessage)
        switchState(state: .isThinking)
        
        var response = ""
        
        // 基于用户输入生成简单回复
        switch userInput.lowercased() {
            case "你好", "hello", "hi":
                response = "你好！我是龟探长，很高兴为你主持海龟汤！"
            case "再见", "bye", "goodbye":
                response = "再见！期待下次和你玩！"
            case "你是谁":
                response = "我是龟探长，你的海龟汤主持人！"
            default:
                // 增加询问次数
                questionCount += 1
                
                // 检查是否超过10次询问
                if isSuccess {
                    response = "恭喜你! 你已经猜得差不多了，快点击卡片查看完整的汤底吧"
                } else if questionCount > 10 {
                    // 计算猜对率
                    let correctRate = Double(correctGuessCount) / Double(questionCount - 1) // 减1是因为当前这次还没处理
                    var suffix = ""
                    
                    if correctRate >= 0.6 { // 假设60%以上算猜对得挺准
                        suffix = "大部分都猜对了，很厉害哦"
                    } else if correctRate >= 0.3 {
                        suffix = "猜对了一部分，真棒！"
                    } else {
                        suffix = "下次继续加油哦！"
                    }
                    
                    response = "你已经问问题超过10次了，\(suffix)\n快点击卡片查看汤底吧"
                } else {
                    // 调用JudgeBot的guess函数
                    Task {
                        do {
                            let result = try await judgeBot.guess(userInput: userInput, card: card, conversationHistory: conversationHistory)
                            DispatchQueue.main.async {
                                var judgeResponse = result.answer
                                // 检查是否猜对了
                                if result.answer == "是" || result.answer == "成功" {
                                    self.correctGuessCount += 1
                                    if result.answer.contains("成功") {
                                        judgeResponse = "恭喜你! 你已经猜得差不多了，快点击卡片查看完整的汤底吧"
                                        self.isSuccess = true
                                    }
                                }
                                // 更新回复内容
                                let botMessage = Message(isUser: false, content: judgeResponse, userInputForJudge: userInput)
                                self.conversationHistory.append(botMessage)
                                // 增加使用次数
                                InAppPurchaseManager.shared.increaseUseTimes()
                            }
                        } catch {
                            DispatchQueue.main.async {
                                let errorMessage = Message(isUser: false, content: "哎呀我挂了，请稍后再问我！")
                                self.conversationHistory.append(errorMessage)
                            }
                        }
                    }
                }
        }
        
        if !response.isEmpty {
            // 添加机器人回复到历史记录
            let botMessage = Message(isUser: false, content: response)
            conversationHistory.append(botMessage)
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
        "你好！我是\(TurtleBot.name)，欢迎来到我的房间。这个地图上有很多隐藏的机关，找到并点击它们，开始探索吧!\n如果你想继续解海龟汤，点击桌面上的纸张即可回到主界面。\n对了，帮忙双击下我的龟脑袋，我先去休息了...",
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


// 龟龟通知视图组件
struct TurtleNotificationView: View {
    @ObservedObject var cardManager: CardManager
    @ObservedObject private var turtleBot = TurtleBot.shared
    // 添加状态变量来跟踪拖动偏移量和当前位置
    @State private var dragOffset = CGSize.zero
    @State private var currentPosition = CGSize.zero
    
    var body: some View {
        // 整体容器，包含turtle图片和搜索框，实现一起拖动
        HStack(spacing: 0) {
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
        .position(TurtleBot.shared.getTurtlePosition()) // 定位到屏幕中下位置
    }
}


// 龟龟裁判视图组件
struct TurtleJudgeView: View {
    @ObservedObject var cardManager: CardManager
    @ObservedObject var purchaseManager: InAppPurchaseManager
    @Binding var showPurchaseView: Bool
    @ObservedObject private var turtleBot = TurtleBot.shared
    @State private var userInput: String = ""
    // 添加状态变量来跟踪拖动偏移量和当前位置
    @State private var dragOffset = CGSize.zero
    @State private var currentPosition = CGSize.zero
    @State private var playGuess = false
    // 添加动画状态变量
    @State private var scale: CGFloat = 1.0
    
    // 计算属性：获取当前显示的卡片
    private func currentCard() -> Card {
        //print("\(cardManager.currentIndex) \(cardManager.displayCards().count)")
        return cardManager.displayCards()[cardManager.currentIndex]
    }
    
    var body: some View {
        // 整体容器，垂直排列
        VStack(spacing: 10) {
            // 第二行：历史记录显示区域，左对齐
            // 外层容器，设置背景和圆角
            VStack {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 4) {
                            ForEach(turtleBot.conversationHistory) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            // 空视图，用于确保最新消息能够完全显示
                            Color.clear.frame(height: 1)
                                .id("bottom")
                        }
                    }
                    .onChange(of: turtleBot.conversationHistory.count) { _ in
                        // 当对话历史更新时，滚动到最后一条消息
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(height: 100) // 固定高度，支持滚动
            .padding(.horizontal, 15) // 外层水平内边距
            .padding(.vertical, 10)   // 外层垂直内边距
            .background(Color.white.opacity(0.9))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1.0)
            )
            .frame(maxWidth: .infinity, alignment: .leading) // 左对齐
            .opacity(playGuess ? 1 : 0) // 根据playGuess控制透明度

            // 第二行：输入框和发送按钮与turtle图片并排
            HStack(alignment: .top, spacing: 10) {
                // 输入框和发送按钮
                HStack(spacing: 8) {
                    TextField("输入问题...", text: $userInput)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1.0)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(Color.white)
                            .font(.system(size: 18))
                            .padding(12)
                            .background(Color.blue)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 0)
                .onAppear {
                    // 自动聚焦输入框
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .opacity(playGuess ? 1 : 0) // 根据playGuess控制透明度
                
                // turtle图片 - 添加发光效果和缩放动画
                if let turtle = AppConfigs.loadImage(name: TurtleBot.shared.getTurtleIcon()) {
                    Image(uiImage: turtle)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        // 添加缩放动画
                        .scaleEffect(scale)
                        // 添加黄色发光效果
                        .shadow(color: .yellow, radius: 10, x: 0, y: 0)
                        .onTapGesture {
                            // 单击切换playGuess的值
                            playGuess.toggle()
                        }
                        .onTapGesture(count: 2) {
                            playGuess.toggle()
                        }
                        .onAppear {
                            startAnimation()
                        }
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
        .position(TurtleBot.shared.getTurtlePosition()) // 定位到屏幕中下位置
        .onAppear{
            turtleBot.resetConversationHistory(currentCard())
        }
    }

    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 检查是否需要显示购买提示
        if purchaseManager.shouldShowPurchaseAlert(card: nil) {
            showPurchaseView = true
            return
        }
        
        let message = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        userInput = "" // 清空输入框
        
        // 调用TurtleBot的judge方法
        turtleBot.judge(message, card: currentCard())
    }
    
    // 消息气泡组件
    private struct MessageBubble: View {
        let message: Message
        
        var body: some View {
            HStack {
                if message.isUser {
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.trailing, 20) // 为用户消息左侧留出空间
                    Spacer()
                } else {
                    Spacer()
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundColor(Color.black)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.leading, 20) // 为机器人消息右侧留出空间
                }
            }
        }
    }
    
    // 开始循环缩放动画
    private func startAnimation() {
        // 使用SwiftUI的动画系统实现无限循环缩放
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            scale = 1.05
        }
    }
}
