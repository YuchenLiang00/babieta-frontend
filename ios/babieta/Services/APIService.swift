//
//  APIService.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/12.
//

import Combine
import Foundation

// MARK: - Token Manager
class TokenManager: ObservableObject {
    @Published var isLoggedIn: Bool = false

    private let tokenKey = "access_token"
    private let userKey = "current_user"

    var token: String? {
        get {
            UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
            isLoggedIn = newValue != nil
        }
    }

    var currentUser: User? {
        get {
            guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            if let user = newValue {
                let data = try? JSONEncoder().encode(user)
                UserDefaults.standard.set(data, forKey: userKey)
            } else {
                UserDefaults.standard.removeObject(forKey: userKey)
            }
        }
    }

    init() {
        isLoggedIn = token != nil
    }

    func logout() {
        token = nil
        currentUser = nil
        isLoggedIn = false
    }
}

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()

    @Published var tokenManager = TokenManager()

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private init() {}

    // MARK: - Headers
    private var defaultHeaders: [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]

        if let token = tokenManager.token {
            headers["Authorization"] = "Bearer \(token)"
        }

        return headers
    }

    // MARK: - Generic Request Method
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: APIConfig.fullBaseURL + endpoint) else {
            throw APIError(detail: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Add headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add body if provided
        if let body = body {
            request.httpBody = body
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(detail: "Invalid response")
            }

            // Handle HTTP error codes
            if httpResponse.statusCode >= 400 {
                if let errorData = try? decoder.decode(APIError.self, from: data) {
                    throw errorData
                } else {
                    throw APIError(detail: "HTTP Error: \(httpResponse.statusCode)")
                }
            }

            // Decode response
            let result = try decoder.decode(responseType, from: data)
            return result

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError(detail: "Network error: \(error.localizedDescription)")
        }
    }

    // MARK: - Authentication Methods
    func register(email: String, password: String, username: String? = nil, fullName: String? = nil)
        async throws -> AuthResponse
    {
        let requestBody = RegisterRequest(
            email: email,
            password: password,
            username: username,
            full_name: fullName
        )

        let bodyData = try encoder.encode(requestBody)

        return try await request(
            endpoint: "/auth/register",
            method: .POST,
            body: bodyData,
            responseType: AuthResponse.self
        )
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        // FastAPI login expects form data, not JSON
        let bodyString = "username=\(email)&password=\(password)"
        let bodyData = bodyString.data(using: .utf8)

        guard let url = URL(string: APIConfig.fullBaseURL + "/auth/login") else {
            throw APIError(detail: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(detail: "Invalid response")
        }

        if httpResponse.statusCode >= 400 {
            if let errorData = try? decoder.decode(APIError.self, from: data) {
                throw errorData
            } else {
                throw APIError(detail: "Login failed")
            }
        }

        let authResponse = try decoder.decode(AuthResponse.self, from: data)

        // Save token
        await MainActor.run {
            self.tokenManager.token = authResponse.access_token
        }

        // Fetch user info after login
        _ = try await fetchCurrentUser()

        return authResponse
    }

    func fetchCurrentUser() async throws -> User {
        let user = try await request(
            endpoint: "/users/me",
            method: .GET,
            responseType: User.self
        )

        await MainActor.run {
            self.tokenManager.currentUser = user
        }

        return user
    }

    func logout() {
        Task { @MainActor in
            self.tokenManager.logout()
        }
    }

    // MARK: - Vocabulary Methods
    func fetchRandomWords(limit: Int = 10, difficultyLevels: [Int]? = nil) async throws
        -> [Vocabulary]
    {
        var endpoint = "/vocabulary/random?limit=\(limit)"

        if let levels = difficultyLevels, !levels.isEmpty {
            let levelsString = levels.map(String.init).joined(separator: ",")
            endpoint += "&difficulty_levels=\(levelsString)"
        }

        return try await request(
            endpoint: endpoint,
            method: .GET,
            responseType: [Vocabulary].self
        )
    }

    func searchWords(query: String, limit: Int = 20) async throws -> [Vocabulary] {
        let encodedQuery =
            query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = "/vocabulary/?search=\(encodedQuery)&limit=\(limit)"

        return try await request(
            endpoint: endpoint,
            method: .GET,
            responseType: [Vocabulary].self
        )
    }

    func fetchWordsByDifficulty(difficulty: Int, limit: Int = 50) async throws -> [Vocabulary] {
        let endpoint = "/vocabulary/?difficulty=\(difficulty)&limit=\(limit)"

        return try await request(
            endpoint: endpoint,
            method: .GET,
            responseType: [Vocabulary].self
        )
    }

    func fetchWordsByCategory(category: String, limit: Int = 30) async throws -> [Vocabulary] {
        let encodedCategory =
            category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        let endpoint = "/vocabulary/?category=\(encodedCategory)&limit=\(limit)"

        return try await request(
            endpoint: endpoint,
            method: .GET,
            responseType: [Vocabulary].self
        )
    }

    func fetchWordDetail(id: Int) async throws -> Vocabulary {
        return try await request(
            endpoint: "/vocabulary/\(id)",
            method: .GET,
            responseType: Vocabulary.self
        )
    }

    func fetchCategories() async throws -> [String] {
        return try await request(
            endpoint: "/vocabulary/categories",
            method: .GET,
            responseType: [String].self
        )
    }

    // MARK: - Learning Methods
    func fetchLearningProgress() async throws -> LearningProgress {
        return try await request(
            endpoint: "/learning/progress",
            method: .GET,
            responseType: LearningProgress.self
        )
    }

    func submitStudySession(
        vocabularyId: Int,
        isCorrect: Bool,
        learningMode: String = "recognition"
    ) async throws -> StudySessionResponse {
        let requestBody = StudySessionRequest(
            vocabulary_id: vocabularyId,
            is_correct: isCorrect,
            learning_mode: learningMode
        )

        let bodyData = try encoder.encode(requestBody)

        return try await request(
            endpoint: "/learning/study-session",
            method: .POST,
            body: bodyData,
            responseType: StudySessionResponse.self
        )
    }

    func fetchLearningRecords(status: String? = nil, limit: Int = 50) async throws
        -> [LearningRecord]
    {
        var endpoint = "/learning/records?limit=\(limit)"

        if let status = status {
            endpoint += "&status=\(status)"
        }

        return try await request(
            endpoint: endpoint,
            method: .GET,
            responseType: [LearningRecord].self
        )
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}
