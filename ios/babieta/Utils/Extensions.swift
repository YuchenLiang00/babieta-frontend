//
//  Extensions.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    func daysFromNow() -> Int {
        let calendar = Calendar.current
        let startOfNow = calendar.startOfDay(for: Date())
        let startOfTimeStamp = calendar.startOfDay(for: self)
        let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
        return components.day ?? 0
    }
}

// MARK: - Color Extensions
extension Color {
    static let appBackground = Color("AppBackground")
    static let cardBackground = Color("CardBackground")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")

    // 根据学习等级返回颜色
    static func levelColor(for level: Int) -> Color {
        switch level {
        case 0:
            return .red
        case 1:
            return .orange
        case 2:
            return .yellow
        case 3:
            return .green
        case 4:
            return .blue
        default:
            return .purple
        }
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
    }

    func buttonStyle(color: Color) -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(color)
            )
            .foregroundColor(.white)
    }
}

// MARK: - String Extensions
extension String {
    // 俄语文本朗读
    func speakRussian() {
        // TODO: 实现文本朗读功能
        // 可以使用 AVSpeechSynthesizer 来实现
    }

    // 检查是否包含俄语字符
    var containsCyrillic: Bool {
        let cyrillicRange = self.range(of: "\\p{Script=Cyrillic}", options: .regularExpression)
        return cyrillicRange != nil
    }
}

// MARK: - Spaced Repetition Algorithm
struct SpacedRepetitionAlgorithm {
    // SM-2算法的简化版本
    static func calculateNextInterval(currentLevel: Int, isCorrect: Bool) -> Int {
        if !isCorrect {
            return 1  // 答错了，明天再复习
        }

        switch currentLevel {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 7
        case 3:
            return 15
        case 4:
            return 30
        case 5:
            return 60
        default:
            return 90
        }
    }

    // 计算记忆强度
    static func memoryStrength(for word: Word) -> Double {
        guard let lastReview = word.lastReviewDate,
            let nextReview = word.nextReviewDate
        else {
            return 0.0
        }

        let now = Date()
        let totalInterval = nextReview.timeIntervalSince(lastReview)
        let elapsedTime = now.timeIntervalSince(lastReview)

        return max(0, 1 - (elapsedTime / totalInterval))
    }
}

// MARK: - Learning Statistics
struct LearningStatistics {
    static func todayStudiedCount(from words: [Word]) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        return words.filter { word in
            guard let lastReview = word.lastReviewDate else { return false }
            return lastReview >= today && lastReview < tomorrow
        }.count
    }

    static func streakDays(from words: [Word]) -> Int {
        // 计算连续学习天数
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0

        for i in 0..<365 {  // 最多检查一年
            let dayStart = calendar.date(byAdding: .day, value: -i, to: today)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let studiedThatDay = words.contains { word in
                guard let lastReview = word.lastReviewDate else { return false }
                return lastReview >= dayStart && lastReview < dayEnd
            }

            if studiedThatDay {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    static func weeklyProgress(from words: [Word]) -> [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var weeklyData: [Int] = []

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!

            let count = words.filter { word in
                guard let lastReview = word.lastReviewDate else { return false }
                return lastReview >= date && lastReview < nextDate
            }.count

            weeklyData.insert(count, at: 0)
        }

        return weeklyData
    }
}
