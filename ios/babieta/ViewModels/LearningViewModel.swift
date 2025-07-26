//
//  LearningViewModel.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/12.
//

import Combine
import Foundation

@MainActor
class LearningViewModel: ObservableObject {
    @Published var currentWords: [Vocabulary] = []
    @Published var currentWordIndex = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var learningProgress: LearningProgress?
    @Published var searchText = ""
    @Published var searchResults: [Vocabulary] = []
    @Published var isSearching = false

    // Learning session state
    @Published var showAnswer = false
    @Published var sessionCorrectCount = 0
    @Published var sessionTotalCount = 0

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    var currentWord: Vocabulary? {
        guard currentWordIndex < currentWords.count else { return nil }
        return currentWords[currentWordIndex]
    }

    var hasMoreWords: Bool {
        currentWordIndex < currentWords.count - 1
    }

    var sessionAccuracy: Double {
        guard sessionTotalCount > 0 else { return 0 }
        return Double(sessionCorrectCount) / Double(sessionTotalCount)
    }

    init() {
        setupSearchBinding()
    }

    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                if !searchText.isEmpty {
                    Task {
                        await self?.searchWords(query: searchText)
                    }
                } else {
                    self?.searchResults = []
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Word Fetching
    func fetchRandomWords(limit: Int = 10, difficulty: [Int]? = nil) async {
        isLoading = true
        errorMessage = ""

        do {
            let words = try await apiService.fetchRandomWords(
                limit: limit,
                difficultyLevels: difficulty
            )
            currentWords = words
            currentWordIndex = 0
            showAnswer = false
        } catch {
            showErrorMessage(error.localizedDescription)
        }

        isLoading = false
    }

    func fetchWordsByDifficulty(_ difficulty: Int, limit: Int = 50) async {
        isLoading = true
        errorMessage = ""

        do {
            let words = try await apiService.fetchWordsByDifficulty(
                difficulty: difficulty,
                limit: limit
            )
            currentWords = words
            currentWordIndex = 0
            showAnswer = false
        } catch {
            showErrorMessage(error.localizedDescription)
        }

        isLoading = false
    }

    func searchWords(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            let results = try await apiService.searchWords(query: query, limit: 20)
            searchResults = results
        } catch {
            print("Search error: \(error.localizedDescription)")
            searchResults = []
        }

        isSearching = false
    }

    // MARK: - Learning Progress
    func fetchLearningProgress() async {
        do {
            learningProgress = try await apiService.fetchLearningProgress()
        } catch {
            print("Failed to fetch learning progress: \(error.localizedDescription)")
        }
    }

    // MARK: - Study Session
    func submitAnswer(isCorrect: Bool, learningMode: String = "recognition") async {
        guard let currentWord = currentWord else { return }

        do {
            _ = try await apiService.submitStudySession(
                vocabularyId: currentWord.id,
                isCorrect: isCorrect,
                learningMode: learningMode
            )

            // Update session statistics
            sessionTotalCount += 1
            if isCorrect {
                sessionCorrectCount += 1
            }

            // Auto move to next word after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.nextWord()
            }

        } catch {
            showErrorMessage("提交学习记录失败: \(error.localizedDescription)")
        }
    }

    func nextWord() {
        if hasMoreWords {
            currentWordIndex += 1
            showAnswer = false
        } else {
            // Session completed, could show results or fetch new words
            Task {
                await fetchRandomWords()
            }
        }
    }

    func previousWord() {
        if currentWordIndex > 0 {
            currentWordIndex -= 1
            showAnswer = false
        }
    }

    func toggleAnswer() {
        showAnswer.toggle()
    }

    func resetSession() {
        sessionCorrectCount = 0
        sessionTotalCount = 0
        currentWordIndex = 0
        showAnswer = false
    }

    // MARK: - Word Management
    func addWordToLearning(_ vocabulary: Vocabulary) {
        if !currentWords.contains(where: { $0.id == vocabulary.id }) {
            currentWords.append(vocabulary)
        }
    }

    func removeCurrentWord() {
        guard currentWordIndex < currentWords.count else { return }
        currentWords.remove(at: currentWordIndex)

        if currentWordIndex >= currentWords.count && currentWordIndex > 0 {
            currentWordIndex = currentWords.count - 1
        }

        showAnswer = false
    }

    // MARK: - Helper Methods
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    func clearError() {
        errorMessage = ""
        showError = false
    }

    // MARK: - Difficulty Management
    func getWordsForBeginners() async {
        await fetchWordsByDifficulty(1, limit: 30)
    }

    func getWordsForIntermediate() async {
        await fetchWordsByDifficulty(2, limit: 25)
    }

    func getWordsForAdvanced() async {
        await fetchWordsByDifficulty(3, limit: 20)
    }
}
