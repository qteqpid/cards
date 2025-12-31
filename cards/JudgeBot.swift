import Foundation
import SwiftUI

class JudgeBot {
    private let apiKey: String
    private let url = URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!
    
    struct RefereeResult: Codable {
        let answer: String
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func guess(userInput: String, card: Card, conversationHistory: [Message]) async throws -> RefereeResult {
        // 1. 构建请求体
        let body: [String: Any] = [
            "model": "glm-4.6v-flash",
            "messages": [
                ["role": "system", "content": """
                Role: 海龟汤（侧向思维游戏）裁判员

                Context
                海龟汤是一种通过“是/不是/不相关”提问来推导离奇事件真相的游戏。你作为裁判，掌握着唯一的真相。

                Current Game Information
                【题目】：\(card.front.description ?? "")
                【答案】：\(card.back.description ?? "")
                【标签】：\(card.labels?.joined(separator: ",") ?? "")

                Task
                根据提供的【题目】、【答案】和【标签】，对玩家的【猜测】进行严格评审。

                Rules & Constraints
                1. **核心回答限制**：你只能输出以下四个词之一：
                   - "是"：猜测符合真相逻辑。
                   - "不是"：猜测与真相矛盾。
                   - "不相关"：猜测对真相的推导没有帮助或无关痛痒或真相中没提到的细节（且不影响主干）。
                   - "成功"：当玩家通过一系列提问，还原了真相的一半以上的关键要素（包括：起因、经过、结果、关键转折点）。
                2. **特殊回复：提示**：
                   - 如果玩家显式要求“提示”，或者连续 5 次获得“不是”或“不相关”的回应，你必须给出提示。
                   - 提示必须以“提示：”开头。
                   - 提示原则：渐进式启发。先提示“范围”（如：关注时间点），再提示“动作”，最后提示“逻辑矛盾点”。严禁直接透露真相。
                3. **输出格式**：必须严格遵循 JSON 格式：
                   {
                     "answer": "是/不是/不相关/提示：..."
                   }
                4. **语气与风格**：思路部分应专业冷静；“回答”部分严禁出现多余文字或标点。
                """],

                // 添加历史对话记录
                ] + convertHistoryToMessages(conversationHistory) + [
                ["role": "user", "content": "\(userInput)"]
            ],
            "response_format": ["type": "json_object"]
        ]

        print("begin request \(body)")
        
        // 2. 配置 Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 3. 发送请求
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // 4. 解析结果 (兼容 OpenAI 格式)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("curl response: \(json)")
        
        // 检查是否有错误
        if let error = json?["error"] as? [String: Any] {
            let errorCode = error["code"] as? Int ?? 0
            let errorMessage = error["message"] as? String ?? "未知错误"
            throw NSError(domain: "JudgeBotError", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // 解析正常响应
        guard let choices = json?["choices"] as? [[String: Any]],
              let content = choices.first?["message"] as? [String: Any],
              let contentString = content["content"] as? String,
              let contentData = contentString.data(using: .utf8) else {
            throw NSError(domain: "JudgeBotError", code: 500, userInfo: [NSLocalizedDescriptionKey: "响应格式错误"])
        }
        
        return try JSONDecoder().decode(RefereeResult.self, from: contentData)
    }
    
    // 将conversationHistory转换为role为user和assistant的消息数组
    private func convertHistoryToMessages(_ history: [Message]) -> [[String: String]] {
        var messages: [[String: String]] = []
        
        for message in history {
            if !message.isUser, let userInput = message.userInputForJudge {
                // 添加用户输入作为user角色的消息
                messages.append(["role": "user", "content": userInput])
                // 添加助手回复作为assistant角色的消息
                messages.append(["role": "assistant", "content": message.content])
            }
        }
        
        return messages
    }
}
