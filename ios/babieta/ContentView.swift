//
//  ContentView.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var wordManager: WordManager
    @State private var showLearningView = false
    @State private var showSettingsView = false
    @State private var showProgressView = false
    @State private var learningMode: HomeView.LearningMode = .review
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片或渐变
                backgroundView
                
                VStack(spacing: 50) {
                    // 顶部设置按钮
                    topNavigationBar
                    
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
        .sheet(isPresented: $showSettingsView) {
            SettingsView(wordManager: wordManager, isPresented: $showSettingsView)
        }
        .sheet(isPresented: $showProgressView) {
            ProgressStatsView(wordManager: wordManager, isPresented: $showProgressView)
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
    
    // 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            Button(action: {
                showProgressView = true
            }) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                showSettingsView = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary.opacity(0.7))
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // 今日单词展示区域
    private var todayWordSection: some View {
        VStack(spacing: 20) {
            if let todayWord = getTodayWord() {
                VStack(spacing: 15) {
                    Text(todayWord.russian)
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(todayWord.pronunciation)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .italic()
                    
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
                VStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    
                    Text("复习")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("\(wordManager.getWordsForReview().count)个")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .frame(width: 120, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            }
            .disabled(wordManager.getWordsForReview().isEmpty)
            
            // 新词按钮
            Button(action: {
                learningMode = .newWords
                showLearningView = true
            }) {
                VStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Text("新词")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("\(min(wordManager.getNewWordsForToday().count, wordManager.dailyNewWordsTarget))个")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .frame(width: 120, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            }
            .disabled(wordManager.getNewWordsForToday().isEmpty)
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

#Preview {
    ContentView()
}
