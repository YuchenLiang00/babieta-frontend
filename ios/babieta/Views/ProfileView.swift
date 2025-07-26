//
//  ProfileView.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var wordManager: WordManager
    @State private var showSettingsView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 用户信息卡片
                    userInfoSection
                    
                    // 学习成就
                    achievementSection
                    
                    // 功能与设置
                    functionsAndSettingsSection
                }
                .padding()
            }
            .navigationTitle("个人中心")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(wordManager: wordManager, isPresented: $showSettingsView)
        }
    }
    
    // 用户信息区域 - 改为长方形布局
    private var userInfoSection: some View {
        HStack(spacing: 20) {
            // 左侧头像和昵称
            VStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    )
                
                Text("俄语学习者")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 右侧统计信息
            VStack(alignment: .trailing, spacing: 12) {
                // 等级
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text("Lv.4")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                // 学习天数
                VStack(alignment: .trailing, spacing: 4) {
                    Text("学习 \(totalStudyDays) 天")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("连续 \(learningDays) 天")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // 学习成就
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学习成就")
                .font(.system(size: 20, weight: .semibold))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                AchievementBadge(
                    icon: "star.fill",
                    title: "初学者",
                    subtitle: "学会10个单词",
                    isUnlocked: wordManager.words.filter { !$0.isNew }.count >= 10,
                    color: .yellow
                )
                
                AchievementBadge(
                    icon: "flame.fill",
                    title: "坚持者",
                    subtitle: "连续学习7天",
                    isUnlocked: currentStreak >= 7,
                    color: .red
                )
                
                AchievementBadge(
                    icon: "crown.fill",
                    title: "词汇大师",
                    subtitle: "学会100个单词",
                    isUnlocked: wordManager.words.filter { !$0.isNew }.count >= 100,
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // 功能与设置 - 合并原来的快捷功能和设置
    private var functionsAndSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("功能与设置")
                .font(.system(size: 20, weight: .semibold))
            
            VStack(spacing: 8) {
                QuickActionRow(
                    icon: "gearshape.fill",
                    title: "学习设置",
                    subtitle: "调整学习计划和偏好",
                    color: .gray
                ) {
                    showSettingsView = true
                }
                
                QuickActionRow(
                    icon: "arrow.clockwise",
                    title: "重置学习进度",
                    subtitle: "清除所有学习记录",
                    color: .red
                ) {
                    resetLearningProgress()
                }
                
                QuickActionRow(
                    icon: "square.and.arrow.up",
                    title: "导出学习数据",
                    subtitle: "备份学习记录",
                    color: .blue
                ) {
                    exportLearningData()
                }
                
                QuickActionRow(
                    icon: "questionmark.circle",
                    title: "帮助与反馈",
                    subtitle: "使用指南和问题反馈",
                    color: .orange
                ) {
                    showHelp()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // 计算学习天数
    private var learningDays: Int {
        // 简化计算
        let studiedWords = wordManager.words.filter { !$0.isNew }
        return min(studiedWords.count / 5, 30) // 假设每天学5个词
    }
    
    private var totalStudyDays: Int {
        learningDays
    }
    
    private var currentStreak: Int {
        // 简化计算连续学习天数
        let recentStudies = wordManager.words.filter { 
            guard let date = $0.lastReviewDate else { return false }
            return date.timeIntervalSinceNow > -7 * 24 * 3600 // 最近7天
        }
        return min(recentStudies.count / 3, 7)
    }
    
    // 功能实现
    private func resetLearningProgress() {
        for index in wordManager.words.indices {
            wordManager.words[index].learningLevel = 0
            wordManager.words[index].isNew = true
            wordManager.words[index].lastReviewDate = nil
            wordManager.words[index].nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }
        wordManager.saveWords()
    }
    
    private func exportLearningData() {
        // TODO: 实现数据导出功能
        print("导出学习数据")
    }
    
    private func showHelp() {
        // TODO: 显示帮助页面
        print("显示帮助")
    }
}

// 成就徽章组件
struct AchievementBadge: View {
    let icon: String
    let title: String
    let subtitle: String
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 25))
                .foregroundColor(isUnlocked ? color : .gray.opacity(0.5))
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isUnlocked ? .primary : .gray)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? color.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked ? color.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isUnlocked ? 1.0 : 0.9)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// 快捷操作行组件
struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView(wordManager: WordManager())
}
