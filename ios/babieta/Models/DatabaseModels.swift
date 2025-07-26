//
//  DatabaseModels.swift
//  babieta
//
//  Created by AI Assistant on 2025/7/7.
//

import Foundation

// MARK: - 数据库单词模型 (Self-hosted backend models)
struct DatabaseWord: Codable {
    let id: UUID
    let user_id: UUID
    let russian: String
    let chinese: String
    let pronunciation: String
    let examples: [String]
    let partOfSpeech: String
    let learningLevel: Int
    let lastReviewDate: Date?
    let nextReviewDate: Date?
    let isNew: Bool
    let created_at: Date
    let updated_at: Date

    enum CodingKeys: String, CodingKey {
        case id, user_id, russian, chinese, pronunciation, examples
        case partOfSpeech = "part_of_speech"
        case learningLevel = "learning_level"
        case lastReviewDate = "last_review_date"
        case nextReviewDate = "next_review_date"
        case isNew = "is_new"
        case created_at, updated_at
    }

    func toWord() -> Word {
        var word = Word(
            russian: russian,
            chinese: chinese,
            pronunciation: pronunciation,
            examples: examples,
            partOfSpeech: partOfSpeech
        )
        word.id = id
        word.learningLevel = learningLevel
        word.lastReviewDate = lastReviewDate
        word.nextReviewDate = nextReviewDate
        word.isNew = isNew
        return word
    }
}

// MARK: - 数据库学习统计模型
struct DatabaseLearningStats: Codable {
    let user_id: UUID
    let totalWords: Int
    let wordsLearned: Int
    let reviewsCompleted: Int
    let streak: Int
    let lastStudyDate: Date?
    let created_at: Date
    let updated_at: Date

    enum CodingKeys: String, CodingKey {
        case user_id, created_at, updated_at
        case totalWords = "total_words"
        case wordsLearned = "words_learned"
        case reviewsCompleted = "reviews_completed"
        case streak
        case lastStudyDate = "last_study_date"
    }

    func toLearningStats() -> LearningStats {
        return LearningStats(
            userId: user_id,
            totalWords: totalWords,
            wordsLearned: wordsLearned,
            reviewsCompleted: reviewsCompleted,
            streak: streak,
            lastStudyDate: lastStudyDate
        )
    }
}

// MARK: - 数据库用户设置模型
struct DatabaseUserSettings: Codable {
    let user_id: UUID
    let dailyNewWordsTarget: Int
    let backgroundImageIndex: Int
    let isDarkMode: Bool
    let created_at: Date
    let updated_at: Date

    enum CodingKeys: String, CodingKey {
        case user_id, created_at, updated_at
        case dailyNewWordsTarget = "daily_new_words_target"
        case backgroundImageIndex = "background_image_index"
        case isDarkMode = "is_dark_mode"
    }

    func toUserSettings() -> UserSettings {
        return UserSettings(
            userId: user_id,
            dailyNewWordsTarget: dailyNewWordsTarget,
            backgroundImageIndex: backgroundImageIndex,
            isDarkMode: isDarkMode
        )
    }
}

// MARK: - 应用内模型
struct LearningStats {
    let userId: UUID
    var totalWords: Int = 0
    var wordsLearned: Int = 0
    var reviewsCompleted: Int = 0
    var streak: Int = 0
    var lastStudyDate: Date?

    init(userId: UUID) {
        self.userId = userId
    }

    init(
        userId: UUID, totalWords: Int, wordsLearned: Int, reviewsCompleted: Int, streak: Int,
        lastStudyDate: Date?
    ) {
        self.userId = userId
        self.totalWords = totalWords
        self.wordsLearned = wordsLearned
        self.reviewsCompleted = reviewsCompleted
        self.streak = streak
        self.lastStudyDate = lastStudyDate
    }
}

struct UserSettings {
    let userId: UUID
    var dailyNewWordsTarget: Int = 20
    var backgroundImageIndex: Int = 0
    var isDarkMode: Bool = false

    init(userId: UUID) {
        self.userId = userId
    }

    init(userId: UUID, dailyNewWordsTarget: Int, backgroundImageIndex: Int, isDarkMode: Bool) {
        self.userId = userId
        self.dailyNewWordsTarget = dailyNewWordsTarget
        self.backgroundImageIndex = backgroundImageIndex
        self.isDarkMode = isDarkMode
    }
}
