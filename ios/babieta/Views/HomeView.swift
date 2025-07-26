//
//  HomeView.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var wordManager: WordManager
    @State private var showLearningView = false
    @State private var learningMode: LearningMode = .review
    
    enum LearningMode {
        case review, newWords
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片或渐变
                backgroundView
                
                VStack(spacing: 50) {
                    Spacer()
                    
                    // 今日单词展示区域
                    todayWordSection
                    
                    Spacer()
                    
                    // 学习按钮区域
                    learningButtonsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 30)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showLearningView) {
            LearningView(
                wordManager: wordManager,
                mode: learningMode,
                isPresented: $showLearningView
            )
        }
    }
    
    // 背景视图
    private var backgroundView: some View {
        LinearGradient(
            colors: wordManager.isDarkMode ? 
                [Color.black.opacity(0.8), Color.blue.opacity(0.3)] :
                [Color.blue.opacity(0.1), Color.white.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 今日单词展示区域
    private var todayWordSection: some View {
        VStack(spacing: 20) {
            if let todayWord = getTodayWord() {
                VStack(spacing: 15) {
                    Text(todayWord.russian)
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(todayWord.chinese)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .opacity(0.8)
                }
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 15) {
                    Text("准备好了吗？")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.primary)
                    
                    Text("开始今天的学习吧")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 30)
            }
        }
    }
    
    // 学习按钮区域
    private var learningButtonsSection: some View {
        HStack(spacing: 30) {
            // 复习按钮
            Button(action: {
                learningMode = .review
                showLearningView = true
            }) {
                LearningButtonView(
                    icon: "arrow.clockwise.circle.fill",
                    iconColor: .blue,
                    number: "\(wordManager.getWordsForReview().count)",
                    label: "复习"
                )
            }
            .disabled(wordManager.getWordsForReview().isEmpty)
            
            // 新词按钮
            Button(action: {
                learningMode = .newWords
                showLearningView = true
            }) {
                LearningButtonView(
                    icon: "plus.circle.fill",
                    iconColor: .green,
                    number: "\(wordManager.getNewWordsCount())",
                    label: "新词"
                )
            }
            .disabled(wordManager.getNewWordsCount() == 0)
        }
    }
    
    // 获取今日单词
    private func getTodayWord() -> Word? {
        let reviewWords = wordManager.getWordsForReview()
        let newWords = wordManager.getNewWordsForToday()
        
        if !reviewWords.isEmpty {
            return reviewWords.first
        } else if !newWords.isEmpty {
            return newWords.first
        }
        return nil
    }
}

// 统一的学习按钮样式组件
struct LearningButtonView: View {
    let icon: String
    let iconColor: Color
    let number: String
    let label: String
    
    var body: some View {
        HStack(spacing: 15) {
            // 左侧图标
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            // 右侧文字信息
            VStack(alignment: .leading, spacing: 4) {
                Text(number)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .frame(width: 150, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    HomeView(wordManager: WordManager())
}
