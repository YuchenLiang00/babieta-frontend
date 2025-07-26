//
//  ProgressView.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI
import Charts

struct ProgressStatsView: View {
    @ObservedObject var wordManager: WordManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 学习概览卡片
                    overviewCards
                    
                    // 学习进度环形图
                    progressRing
                    
                    // 最近学习的单词
                    recentWordsSection
                }
                .padding()
            }
            .navigationTitle("学习统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // 概览卡片
    private var overviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            StatCard(
                title: "总词汇",
                value: "\(wordManager.words.count)",
                icon: "book.fill",
                color: .blue
            )
            
            StatCard(
                title: "已掌握",
                value: "\(masteredWordsCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "待复习",
                value: "\(wordManager.getWordsForReview().count)",
                icon: "arrow.clockwise.circle.fill",
                color: .orange
            )
            
            StatCard(
                title: "新单词",
                value: "\(wordManager.getNewWordsForToday().count)",
                icon: "plus.circle.fill",
                color: .purple
            )
        }
    }
    
    // 进度环形图
    private var progressRing: some View {
        VStack(spacing: 15) {
            Text("学习进度")
                .font(.system(size: 20, weight: .semibold))
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: progressPercentage)
                
                VStack {
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.system(size: 24, weight: .bold))
                    Text("完成度")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
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
    
    // 最近学习的单词
    private var recentWordsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近学习")
                .font(.system(size: 20, weight: .semibold))
            
            LazyVStack(spacing: 10) {
                ForEach(recentlyStudiedWords, id: \.id) { word in
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(word.russian)
                                .font(.system(size: 18, weight: .medium))
                            Text(word.chinese)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("等级 \(word.learningLevel)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                            
                            if let lastReview = word.lastReviewDate {
                                Text(lastReview, style: .relative)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.6))
                    )
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
    
    // 计算已掌握的单词数量
    private var masteredWordsCount: Int {
        wordManager.words.filter { $0.learningLevel >= 3 }.count
    }
    
    // 计算进度百分比
    private var progressPercentage: Double {
        guard !wordManager.words.isEmpty else { return 0 }
        return Double(masteredWordsCount) / Double(wordManager.words.count)
    }
    
    // 最近学习的单词
    private var recentlyStudiedWords: [Word] {
        wordManager.words
            .filter { $0.lastReviewDate != nil }
            .sorted { ($0.lastReviewDate ?? Date.distantPast) > ($1.lastReviewDate ?? Date.distantPast) }
            .prefix(5)
            .map { $0 }
    }
}

// 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧图标
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 35)
            
            Spacer()
            
            // 右侧文字信息
            VStack(alignment: .trailing, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
}

#Preview {
    ProgressStatsView(wordManager: WordManager(), isPresented: .constant(true))
}
