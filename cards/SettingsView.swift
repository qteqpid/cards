//  SettingsView.swift
//  party_fun
//
//  Created by AI Assistant on 2024/10/17.
//

import SwiftUI
import UIKit
import Combine

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    var backgroundColor: Color
    private let settingHeaderColor = Color(red: 0.99, green: 0.98, blue: 0.95)
    
    var body: some View {
        ZStack {
            // 背景色
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            // 主内容
            VStack {
                // 设置列表
                List {
                   Section() {
                       // 海龟汤来了
                    //    SettingsRow(iconName: "app_logo_moon_mini.jpg", title: "海龟汤来了", isLast: false) {
                    //        Image(systemName: "chevron.right")
                    //            .foregroundColor(.gray)
                    //    }
                    //    .onTapGesture {
                    //         AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6749227316")
                    //     }

                       SettingsRow(iconName: "app_logo_fun_mini.jpg", title: "聚会卡牌", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                           AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6752017904")
                       }

                       SettingsRow(iconName: "app_logo_english_mini.jpg", title: "打卡背单词", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                           AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6752640506")
                       }
                    
                        SettingsRow(iconName: "app_logo_class_mini.jpg", title: "简易课程表", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                           AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6748935753")
                       }

                       SettingsRow(iconName: "app_logo_idea_mini.png", title: "灵光一现", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                           AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6748610782")
                       }
                    
                        SettingsRow(iconName: "app_logo_passbox_mini.png", title: "密码柜", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                           AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6748747342")
                       }

                        SettingsRow(iconName: "app_logo_math_mini.jpg", title: "开心学口算", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                           AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6748607355")
                       }

                        SettingsRow(iconName: "app_logo_cleaner_mini.png", title: "相册清理助手", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                           AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6748892725")
                       }

                       SettingsRow(iconName: "app_logo_draw_mini.png", title: "绘图白板", isLast: false) {
                           Image(systemName: "chevron.right")
                               .foregroundColor(.gray)
                       }
                       .onTapGesture {
                           AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6749177569")
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
                       SimpleSettingsRow(iconName: "star", title: "给我们评分", isLast: false)
                        .onTapGesture {
                            // app store评分界面
                            AppConfigs.openUrl(url: "itms-apps://itunes.apple.com/app/id6749227316?action=write-review")
                        }
                       SettingsRowWithText(iconName: "info.circle", title: "版本号", text: AppConfigs.appVersion, isLast: true)
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
