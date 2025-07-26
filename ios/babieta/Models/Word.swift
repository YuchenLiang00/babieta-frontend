//
//  Word.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import Foundation

struct Word: Identifiable, Codable {
    var id = UUID()
    let russian: String
    let chinese: String
    let pronunciation: String
    let examples: [String]
    let partOfSpeech: String // 词性（用俄语表示）
    var learningLevel: Int = 0 // 学习次数，用于遗忘曲线算法
    var lastReviewDate: Date?
    var nextReviewDate: Date?
    var isNew: Bool = true
    
    init(russian: String, chinese: String, pronunciation: String, examples: [String], partOfSpeech: String = "сущ.") {
        self.russian = russian
        self.chinese = chinese
        self.pronunciation = pronunciation
        self.examples = examples
        self.partOfSpeech = partOfSpeech
        // 新单词应该立即可以学习，不设置未来的复习时间
        self.nextReviewDate = nil
    }
    
    // 根据遗忘曲线计算下次复习时间
    mutating func updateReviewSchedule(isKnown: Bool) {
        lastReviewDate = Date()
        
        if isKnown {
            learningLevel += 1
            isNew = false
            
            // 基于艾宾浩斯遗忘曲线的间隔时间（分钟）
            let intervals: [Int] = [
                1440,      // 1天后 (24 * 60 = 1440)
                7200,      // 5天后 (5 * 24 * 60 = 7200)
                14400,     // 10天后 (10 * 24 * 60 = 14400)
                43200,     // 30天后 (30 * 24 * 60 = 43200)
                129600     // 90天后 (90 * 24 * 60 = 129600)
            ]
            
            let minuteInterval = learningLevel <= intervals.count ? 
                intervals[learningLevel - 1] : intervals.last!
            
            nextReviewDate = Calendar.current.date(byAdding: .minute, value: minuteInterval, to: Date())
        } else {
            // 不认识则重置学习进度，但保留最低等级
            learningLevel = max(0, learningLevel - 1)
            nextReviewDate = Calendar.current.date(byAdding: .minute, value: 20, to: Date())
        }
    }
}
