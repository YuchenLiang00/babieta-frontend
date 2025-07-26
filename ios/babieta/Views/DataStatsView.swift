//
//  DataStatsView.swift
//  babieta
//
//  Created by AI Assistant on 2025/7/12.
//

import SwiftUI

struct DataStatsView: View {
    @ObservedObject var wordManager: WordManager

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 单词书进度区域
                vocabularyProgressSection

                // 连续学习天数日历
                studyStreakCalendar
            }
            .padding()
        }
    }

    // MARK: - 单词书进度区域
    private var vocabularyProgressSection: some View {
        VStack(spacing: 20) {
            Text("单词书进度")
                .font(.system(size: 24, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                // 左侧：圆环进度图
                progressRingView

                // 右侧：数字统计
                statisticsNumbersView
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // 圆环进度图
    private var progressRingView: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 120, height: 120)

            // 已学会单词（绿色）
            Circle()
                .trim(from: 0, to: masteredPercentage)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            // 需复习单词（黄色）
            Circle()
                .trim(from: masteredPercentage, to: masteredPercentage + reviewingPercentage)
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            // 中心文字
            VStack(spacing: 2) {
                Text("\(Int((masteredPercentage + reviewingPercentage) * 100))%")
                    .font(.system(size: 18, weight: .bold))
                Text("已学习")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    // 数字统计
    private var statisticsNumbersView: some View {
        VStack(spacing: 16) {
            // 已学会
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                Text("已学会")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(wordManager.getMasteredWordsCount())")
                    .font(.system(size: 18, weight: .semibold))
            }

            // 需复习
            HStack {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 12, height: 12)
                Text("需复习")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(reviewingWordsCount)")
                    .font(.system(size: 18, weight: .semibold))
            }

            // 待学习
            HStack {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 12)
                Text("待学习")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(wordManager.getNewWordsCount())")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 连续学习天数日历
    private var studyStreakCalendar: some View {
        VStack(spacing: 20) {
            HStack {
                Text("连续学习天数")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                Text("\(currentStreak) 天")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
            }

            // 两周日历
            VStack(spacing: 12) {
                // 上周（第一行）
                weekRowView(weekOffset: -1, title: "上周")

                // 本周（第二行）
                weekRowView(weekOffset: 0, title: "本周")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // 周行视图
    private func weekRowView(weekOffset: Int, title: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(0..<7) { dayIndex in
                    let date = getDateForWeek(weekOffset: weekOffset, dayIndex: dayIndex)
                    dayCircleView(for: date)
                }
            }
        }
    }

    // 日期圆圈视图
    private func dayCircleView(for date: Date) -> some View {
        let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
        let hasStudied = hasStudiedOn(date)
        let dayNumber = Calendar.current.component(.day, from: date)

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(hasStudied ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)

                if isToday {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 32, height: 32)
                }

                Text("\(dayNumber)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(hasStudied ? .white : .primary)
            }

            // 星期标签
            Text(dayOfWeekLabel(for: date))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 计算属性和辅助方法

    private var masteredPercentage: Double {
        let progressPercentages = wordManager.getProgressPercentages()
        return progressPercentages.mastered
    }

    private var reviewingPercentage: Double {
        let progressPercentages = wordManager.getProgressPercentages()
        return progressPercentages.reviewing
    }

    private var reviewingWordsCount: Int {
        return wordManager.words.filter { !$0.isNew && $0.learningLevel < 3 }.count
    }

    private var currentStreak: Int {
        return LearningStatistics.streakDays(from: wordManager.words)
    }

    // 获取指定周和天的日期
    private func getDateForWeek(weekOffset: Int, dayIndex: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()

        // 获取本周的开始日期（周一）
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return today
        }

        // 调整到周一开始（如果需要）
        let weekday = calendar.component(.weekday, from: weekStart)
        let daysFromMonday = (weekday == 1) ? -6 : -(weekday - 2)
        guard let mondayStart = calendar.date(byAdding: .day, value: daysFromMonday, to: weekStart)
        else {
            return today
        }

        // 计算目标周的开始日期
        guard
            let targetWeekStart = calendar.date(
                byAdding: .weekOfYear, value: weekOffset, to: mondayStart)
        else {
            return today
        }

        // 返回该周的指定日期
        return calendar.date(byAdding: .day, value: dayIndex, to: targetWeekStart) ?? today
    }

    // 检查指定日期是否有学习记录
    private func hasStudiedOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return wordManager.words.contains { word in
            guard let lastReview = word.lastReviewDate else { return false }
            return lastReview >= dayStart && lastReview < dayEnd
        }
    }

    // 获取星期标签
    private func dayOfWeekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

#Preview {
    DataStatsView(wordManager: WordManager())
}
