import SwiftUI
import Combine
import UIKit

private let maxQuestionCount = 10

struct PlayRoomView: View {
    let card: Card
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var purchaseManager: InAppPurchaseManager
    @Binding var showPurchaseView: Bool
    @ObservedObject private var judgeBot = JudgeBot()
    @StateObject private var musicPlayer = MusicPlayer.shared
    @State private var userInput: String = ""
    @State private var conversationHistory: [Message] = []
    @State private var questionCount = 0
    @State private var correctGuessCount = 0
    @State private var isSuccess = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                headerView
                Divider()
                    .background(Color.gray.opacity(0.3))
                soupAreaView
                messagesListView
                inputAreaView
            }
        }
        .onAppear {
            resetConversationHistory()
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                triggerHapticFeedback()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                if let cardTitle = card.front.title {
                    Text("《\(cardTitle)》")
                        .font(.headline)
                        .foregroundColor(.white)
                } else {
                    Text("龟探长玩汤")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    showSoupContent()
                }) {
                    Label("查看汤底", systemImage: "doc.text")
                }
                
                Button(action: {
                    triggerHapticFeedback()
                    musicPlayer.togglePlayback()
                }) {
                    Label(musicPlayer.isPlaying ? "关闭音乐" : "开启音乐", systemImage: musicPlayer.isPlaying ? "speaker.slash" : "speaker.wave.2")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }
    
    private var messagesListView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    ForEach(conversationHistory) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                    
                    // 显示加载状态
                    if judgeBot.isGuessing {
                        LoadingMessageRow()
                            .id("loading")
                    }
                    
                    Color.clear.frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical, 16)
            }
            .onChange(of: conversationHistory.count) { _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: judgeBot.isGuessing) { _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    private var inputAreaView: some View {
        HStack(spacing: 12) {
            Button(action: {
                sendHintMessage()
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
            }
            
            HStack {
                TextField("", text: $userInput, prompt: Text("开始提问吧...").foregroundColor(.gray))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
            }
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(16)
            
            Button(action: {
                sendMessage()
            }) {
                Image(systemName: "paperplane.circle")
                    .font(.system(size: 28))
                    .foregroundColor(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || judgeBot.isGuessing ? .gray : .white)
            }
            .disabled(judgeBot.isGuessing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black)
    }
    
    private var soupAreaView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 6) {
                if let labels = card.labels, !labels.isEmpty {
                    HStack {
                        ForEach(labels, id: \.self) {
                            label in
                            Text("#\(label)")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                                .padding(.trailing, 4)
                                .padding(.vertical, 4)
                                .background(Color.clear)
                                .cornerRadius(4)
                        }
                    }
                }
                
                if let description = card.front.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        //.background(Color(hex: "#4682B4")) //4682B4
        .background(
            Group {
                if let bgImage = AppConfigs.loadImage(name: "soup_bg.jpg") {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(hex: "#4682B4")
                }
            }
        )
        .border(Color(hex: "#3A6B8A"), width: 2) // 添加边框
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2) // 添加阴影
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 150)
    }
    
    private func resetConversationHistory() {
        // 清空对话历史
        conversationHistory.removeAll()
        // 重置询问次数和猜对次数
        questionCount = 0
        correctGuessCount = 0
        isSuccess = false
        
        var instruction = ""
        if !UserTracker.shared.hasShownInstruction {
            instruction = "你有10次机会可以提问，我会根据汤底回答\"是/不是/不相关\"。\n"
            UserTracker.shared.hasShownInstruction = true
        }
        
        let defaultMessage = Message(isUser: false, content: "hi，\(instruction)请开始提问吧。实在想不出来也可以点左下角的问号，找我要提示哦")
        conversationHistory.append(defaultMessage)
    }
    
    private func sendMessage() {
        triggerHapticFeedback()
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if purchaseManager.shouldShowPurchaseAlert(card: card) {
            showPurchaseView = true
            return
        }
        
        let message = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        userInput = ""
        
        judge(message, card: card)
    }
    
    private func sendHintMessage() {
        triggerHapticFeedback()
        if judgeBot.isGuessing {
            return
        }
        
        if questionCount == 0 {
            let hintMessage = "别急着要提示嘛～先试着问几个问题吧！你可以问一些比如：\n• 有人死亡吗？\n• 主角是人吗？\n• 有超自然灵异元素吗？加油，你能行的！"
            let botMessage = Message(isUser: false, content: hintMessage)
            conversationHistory.append(botMessage)
            return
        }
        
        if purchaseManager.shouldShowPurchaseAlert(card: card) {
            showPurchaseView = true
            return
        }

        judge("我需要提示", card: card)
    }
    
    private func showSoupContent() {
        triggerHapticFeedback()
        if questionCount == 0 {
            let hintMessage = "别急着看汤底嘛～先试着问几个问题吧！你可以问一些比如：\n• 有人死亡吗？\n• 主角是人吗？\n• 有超自然灵异元素吗？加油，你能行的！"
            let botMessage = Message(isUser: false, content: hintMessage)
            conversationHistory.append(botMessage)
            return
        }
        let soupContent = card.back.description ?? "暂无汤底内容"
        let soupMessage = "【汤底】\n\(soupContent)"
        let botMessage = Message(isUser: false, content: soupMessage)
        conversationHistory.append(botMessage)
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func judge(_ userInput: String, card: Card) {
        // 添加用户输入到历史记录
        let userMessage = Message(isUser: true, content: userInput)
        conversationHistory.append(userMessage)
        
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
            } else if questionCount > maxQuestionCount {
                // 计算猜对率
                let correctRate = Double(correctGuessCount) / Double(maxQuestionCount)
                var suffix = ""
                
                if correctRate >= 0.6 {
                    suffix = "大部分都猜对了，很厉害哦"
                } else if correctRate >= 0.3 {
                    suffix = "猜对了一部分，真棒！"
                } else {
                    suffix = "下次继续加油哦！"
                }
                
                response = "你已经问问题超过10次了，\(suffix)\n快去查看汤底吧"
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
                                    judgeResponse = "恭喜你! 你已经猜得差不多了，快去查看完整的汤底吧"
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
                            let errorMessage = Message(isUser: false, content: "哎呀我网络挂了，请稍后再问我！实在抱歉，我也不想这样...")
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
}

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer()

                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("我")
                            .font(.caption)
                            .foregroundColor(.gray)

                        messageBubble
                    }
                    userAvatar
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    botAvatar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("龟探长")
                            .font(.caption)
                            .foregroundColor(.gray)

                        messageBubble
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var messageBubble: some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(message.isUser ? .white : .white)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if message.isUser {
                        RightBubbleShape()
                            .fill(Color(red: 0.2, green: 0.6, blue: 0.2))
                    } else {
                        LeftBubbleShape()
                            .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                    }
                }
            )
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isUser ? .trailing : .leading)
    }
    
    private var userAvatar: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
            )
    }
    
    private var botAvatar: some View {
        Group {
            if let image = AppConfigs.loadImage(name: "turtle_detective_icon.png") {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "tortoise.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                    )
            }
        }
    }
}

// 加载消息行 - 显示三个点动画
struct LoadingMessageRow: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            botAvatar
            VStack(alignment: .leading, spacing: 4) {
                Text("龟探长")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .opacity(dotCount >= 1 ? 1.0 : 0.3)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .opacity(dotCount >= 2 ? 1.0 : 0.3)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .opacity(dotCount >= 3 ? 1.0 : 0.3)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    LeftBubbleShape()
                        .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .onReceive(timer) { _ in
            withAnimation {
                dotCount = (dotCount % 3) + 1
            }
        }
    }
    
    private var botAvatar: some View {
        Group {
            if let image = AppConfigs.loadImage(name: "turtle_detective_icon.png") {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "tortoise.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                    )
            }
        }
    }
}
