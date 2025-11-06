//  SettingsView.swift
//
//  Created by AI Assistant on 2024/10/17.
//

import SwiftUI
import UIKit
import Combine

// 应用信息模型
struct AppInfo {
    let iconName: String
    let title: String
    let appleId: String
}

struct SettingsView: View {
    @ObservedObject var purchaseManager: InAppPurchaseManager
    @Environment(\.presentationMode) var presentationMode
    var backgroundColor: Color
    private let settingHeaderColor = Color(red: 0.99, green: 0.98, blue: 0.95)

    // 应用列表数据
    private let apps: [AppInfo] = [
        AppInfo(iconName: "app_logo_class_mini.jpg", title: "ins课程表，超好用好看课程表", appleId: "6748935753"),
        //AppInfo(iconName: "app_logo_moon_mini.jpg", title: "海龟汤来了，风靡全球推理游戏", appleId: "6749227316"),
        AppInfo(iconName: "app_logo_english_mini.jpg", title: "贝塔英语，背单词很轻松", appleId: "6748849691"),
        AppInfo(iconName: "app_logo_idea_mini.png", title: "灵光一现，帮你随时记录想法", appleId: "6748610782"),
        AppInfo(iconName: "app_logo_wrong_mini.jpg", title: "超级错题本，拍照整理作业错题", appleId: "6753838149"),
        AppInfo(iconName: "app_logo_math_mini.jpg", title: "小爱口算，小学生口算练习神器", appleId: "6748607355"),
        AppInfo(iconName: "app_logo_chinese_mini.png", title: "汉字卡片，幼儿识字好帮手", appleId: "6753268205"),
        AppInfo(iconName: "app_logo_fun_mini.jpg", title: "聚会卡牌，团建聚会破冰游戏", appleId: "6752017904"),
        AppInfo(iconName: "app_logo_passbox_mini.png", title: "密码柜，生活密码全记住", appleId: "6748747342"),
        AppInfo(iconName: "app_logo_cleaner_mini.png", title: "相册清理助手", appleId: "6748892725"),
        AppInfo(iconName: "app_logo_draw_mini.png", title: "绘图白板", appleId: "6749177569"),
        AppInfo(iconName: "app_logo_ishots_mini.png", title: "iShots", appleId: "6754618226")

    ]

    // 使用map将应用数据转换为视图数组
    private var appViews: [AnyView] {
        apps.map { app in
            AnyView(
                SettingsRow(iconName: app.iconName, title: app.title, isLast: false) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    AppConfigs.openUrl(url: AppConfigs.getAppStoreUrl(appId: app.appleId))
                }
            )
        }
    }
    
    var body: some View {
        ZStack {
            // 背景色
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            // 主内容
            VStack {
                // 设置列表
                List {
                   Section() {
                       // 使用ForEach遍历视图数组，实现map + foreach的展示方式
                       ForEach(appViews.indices, id: \.self) { index in
                           appViews[index]
                       }
                   }

                    // 联系我们分组
                   Section(header: Text("联系我们").foregroundColor(settingHeaderColor).font(.title2)) {
                       // 自定义组件用于打开小红书App
                       SettingsRow(iconName: "rednote_icon.png", title: "Qteqpid", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                            // 小红书App的URL Scheme
                           AppConfigs.openUrl(url: "https://xhslink.com/m/6ooRgc36BTt")
                       }
                       SettingsRow(iconName: "email_icon.png", title: "glloveyp@163.com", isLast: true) {
                            EmptyView()
                       }
                    
                   }
                    
                    // 其他分组
                   Section(header: Text("其他").foregroundColor(settingHeaderColor).font(.title2)) {
                       SimpleSettingsRow(iconName: "star", title: "给我们好评", isLast: false)
                        .onTapGesture {
                            // app store评分界面
                            AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6749227316?action=write-review")
                        }
                       SettingsRowWithBadgeAndArrow(iconName: "info.circle", title: "版本号 \(AppConfigs.appVersion)", badgeText: "检查更新", badgeColor: Color.purple, isLast: true)
                        .onTapGesture {
                           AppConfigs.openUrl(url: AppConfigs.getAppStoreUrl(appId: "6749227316"))
                       }
                        .gesture(
                            LongPressGesture(minimumDuration: 3)
                                .onEnded { _ in
                                    purchaseManager.activatePremium()
                                }
                        )
                   }
                }
                .background(backgroundColor)
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
            }
        }
        .navigationTitle("Qteqpid的更多宝藏作品")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
        }
        
    }
}
