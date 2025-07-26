//
//  APIModels.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/12.
//

import Foundation

// MARK: - API Configuration
struct APIConfig {
    private static let configFileName = "api_config"
    private static let configFileExtension = "json"

    static var baseURL: String {
        return loadConfig()["baseURL"] ?? ""
    }

    static var apiVersion: String {
        return loadConfig()["apiVersion"] ?? ""
    }

    static var fullBaseURL: String {
        return baseURL + apiVersion
    }

    private static func loadConfig() -> [String: String] {
        guard
            let url = Bundle.main.url(
                forResource: configFileName, withExtension: configFileExtension),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
                as? [String: String]
        else {
            return [:]
        }
        return json
    }
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let username: String?
    let full_name: String?
}

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
}

// MARK: - User Models
struct User: Codable {
    let id: Int
    let email: String
    let username: String?
    let full_name: String?
    let is_active: Bool
    let created_at: String
}

// MARK: - Vocabulary Models
struct Vocabulary: Identifiable, Codable {
    let id: Int
    let russian_word: String
    let english_translation: String?
    let chinese_translation: String?
    let pronunciation: String?
    let difficulty_level: Int
    let category: String?
    let meanings: [Meaning]?

    // Convert API model to local Word model
    func toWord() -> Word {
        return Word(
            russian: russian_word,
            chinese: chinese_translation ?? english_translation ?? "",
            pronunciation: pronunciation ?? "",
            examples: meanings?.compactMap { $0.example_ru } ?? [],
            partOfSpeech: category ?? "сущ."
        )
    }
}

struct Meaning: Codable {
    let id: Int
    let translation: String
    let definition: String?
    let example_ru: String?
    let example_tl: String?
}

// MARK: - Learning Models
struct StudySessionRequest: Codable {
    let vocabulary_id: Int
    let is_correct: Bool
    let learning_mode: String  // "recognition", "recall", "listening"
}

struct StudySessionResponse: Codable {
    let id: Int
    let vocabulary_id: Int
    let is_correct: Bool
    let learning_mode: String
    let created_at: String
}

struct LearningProgress: Codable {
    let new: Int
    let learning: Int
    let mastered: Int
    let forgotten: Int
    let total: Int
}

struct LearningRecord: Codable {
    let id: Int
    let vocabulary_id: Int
    let status: String  // "new", "learning", "mastered", "forgotten"
    let last_reviewed: String?
    let next_review: String?
    let difficulty_level: Int
}

// MARK: - API Error Models
struct APIError: Codable, Error {
    let detail: String

    var localizedDescription: String {
        return detail
    }
}

// MARK: - Generic API Response
struct APIResponse<T: Codable>: Codable {
    let data: T?
    let message: String?
    let error: String?
}
