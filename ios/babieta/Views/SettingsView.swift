//
//  SettingsView.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var wordManager: WordManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                // 学习设置
                Section("学习设置") {
                    HStack {
                        Text("每日新词目标")
                        Spacer()
                        Stepper(
                            "\(wordManager.dailyNewWordsTarget)",
                            value: $wordManager.dailyNewWordsTarget,
                            in: 5...50,
                            step: 5)
                    }
                }

                // 外观设置
                Section("外观设置") {
                    Toggle("深色模式", isOn: $wordManager.isDarkMode)

                    HStack {
                        Text("背景图片")
                        Spacer()
                        Picker("背景图片", selection: $wordManager.backgroundImageIndex) {
                            ForEach(0..<10, id: \.self) { index in
                                Text("背景 \(index + 1)").tag(index)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                // 学习统计
                Section("学习统计") {
                    HStack {
                        Text("总词汇量")
                        Spacer()
                        Text("\(wordManager.words.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("已学单词")
                        Spacer()
                        Text("\(wordManager.words.filter { !$0.isNew }.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("待复习单词")
                        Spacer()
                        Text("\(wordManager.getWordsForReview().count)")
                            .foregroundColor(.secondary)
                    }
                }

                // 数据管理
                Section("数据管理") {
                    Button("重置学习进度") {
                        resetLearningProgress()
                    }
                    .foregroundColor(.red)
                }

                // 账号管理
                Section("账号管理") {
                    // TODO: Implement user management with self-hosted backend
                    HStack {
                        Text("当前用户")
                        Spacer()
                        Text("未登录 (开发模式)")
                            .foregroundColor(.secondary)
                    }

                    Button("退出登录") {
                        signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        wordManager.saveSettings()
                        isPresented = false
                    }
                }
            }
        }
    }

    private func resetLearningProgress() {
        // 重置所有单词的学习进度
        for index in wordManager.words.indices {
            wordManager.words[index].learningLevel = 0
            wordManager.words[index].isNew = true
            wordManager.words[index].lastReviewDate = nil
            wordManager.words[index].nextReviewDate = Calendar.current.date(
                byAdding: .day, value: 1, to: Date())
        }
        wordManager.saveWords()
    }

    private func signOut() {
        // Perform sign out action here
        NotificationCenter.default.post(name: .userDidSignOut, object: nil)
        isPresented = false
    }
}

extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
}

#Preview {
    SettingsView(wordManager: WordManager(), isPresented: .constant(true))
}
