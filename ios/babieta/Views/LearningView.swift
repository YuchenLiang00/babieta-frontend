//
//  LearningView.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI

// 题型枚举
enum QuestionType: CaseIterable {
    case russianToChineseMultipleChoice  // 看俄选汉
    case russianToChineseListening  // 听俄选汉
    case chineseToRussianMultipleChoice  // 看汉选俄
    case chineseToRussianSpelling  // 看汉拼俄

    var title: String {
        switch self {
        case .russianToChineseMultipleChoice:
            return "看俄选汉"
        case .russianToChineseListening:
            return "听俄选汉"
        case .chineseToRussianMultipleChoice:
            return "看汉选俄"
        case .chineseToRussianSpelling:
            return "看汉拼俄"
        }
    }
}

// 题目数据结构
struct Question: Identifiable, Equatable {
    let id = UUID()
    let wordIndex: Int
    let questionType: QuestionType

    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.wordIndex == rhs.wordIndex && lhs.questionType == rhs.questionType
    }
}

// 单词学习状态
struct WordLearningState {
    let word: Word
    var completedTypes: Set<QuestionType> = []
    var incorrectTypes: Set<QuestionType> = []

    var isFullyCompleted: Bool {
        return completedTypes.count == QuestionType.allCases.count
    }

    // 获取下一个可进行的题型
    // NOTE: this should be carefully designed to ensure it respects the learning flow
    func getNextAvailableType() -> QuestionType? {
        // 如果有错误的题型，优先重做错误题型中最早的一个
        let orderedTypes = QuestionType.allCases
        for type in orderedTypes {
            if incorrectTypes.contains(type) {
                return type
            }
        }

        // 否则按顺序进行未完成的题型
        for type in orderedTypes {
            if !completedTypes.contains(type) {
                return type
            }
        }
        return nil
    }
}

struct LearningView: View {
    @ObservedObject var wordManager: WordManager
    let mode: HomeView.LearningMode
    @Binding var isPresented: Bool

    @StateObject private var audioManager = AudioManager()
    @State private var words: [Word] = []
    @State private var wordStates: [WordLearningState] = []  // 每个单词的学习状态
    @State private var questionQueue: [Question] = []  // 待做题目队列
    @State private var currentQuestion: Question? = nil  // 当前题目
    @State private var selectedAnswer: Int? = nil
    @State private var showResult = false
    @State private var showDetailView = false
    @State private var isCorrect = false
    @State private var options: [String] = []
    @State private var correctAnswerIndex = 0
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var showNextCard = false
    @State private var completedQuestionsCount = 0  // 完成的题目数量
    @State private var showCorrectEffect = false  // 答对时的绿光效果
    @State private var showIncorrectEffect = false  // 答错时的红光效果
    @State private var correctEffectOpacity: Double = 0.0  // 绿光透明度
    @State private var incorrectEffectOpacity: Double = 0.0  // 红光透明度
    @State private var inputText: String = ""  // 拼写题型的输入文本
    @State private var originalWordsCount: Int = 0  // 原始单词数量
    @State private var progressHighlightOffset: CGFloat = 0  // 进度条高光动画偏移
    @State private var showProgressHighlight = false  // 显示进度条高光

    // 题型数量配置（可调整）
    private var questionTypesCount: Int {
        return QuestionType.allCases.count  // 当前为4种题型，可配置
    }

    // 计算总题目数量
    private var totalQuestionsCount: Int {
        return words.count * questionTypesCount
    }

    // 计算当前正在学习的单词
    private var currentWord: Word {
        guard let question = currentQuestion,
            question.wordIndex < words.count
        else {
            return words.first ?? Word(russian: "", chinese: "", pronunciation: "", examples: [])
        }
        return words[question.wordIndex]
    }

    // 当前题型
    private var currentQuestionType: QuestionType {
        return currentQuestion?.questionType ?? .russianToChineseMultipleChoice
    }

    // 判断是否所有单词都已完成
    private var isAllWordsCompleted: Bool {
        return wordStates.allSatisfy { $0.isFullyCompleted }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                backgroundView

                VStack(spacing: 0) {
                    // 顶部导航栏
                    topNavigationBar
                        .padding(.top, 70)  // 进一步下移，避开灵动岛

                    Spacer()

                    // 单词卡片或完成页面
                    if isAllWordsCompleted {
                        completionView
                    } else {
                        wordCardStack(geometry: geometry)
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            loadWords()
            initializeLearning()
        }
    }

    // 初始化学习
    private func initializeLearning() {
        guard !words.isEmpty else { return }

        // 初始化所有单词的学习状态
        wordStates = words.map { WordLearningState(word: $0) }

        // 生成初始题目队列
        generateNextQuestions()

        // 设置第一个问题
        if let firstQuestion = questionQueue.first {
            currentQuestion = firstQuestion
            questionQueue.removeFirst()
            setupCurrentQuestion()
        }
    }

    // 生成下一批题目
    private func generateNextQuestions() {
        var newQuestions: [Question] = []

        // 为每个单词尝试添加下一个可做的题型
        for (index, wordState) in wordStates.enumerated() {
            if let nextType = wordState.getNextAvailableType() {
                let question = Question(wordIndex: index, questionType: nextType)
                newQuestions.append(question)
            }
        }

        // 打乱题目顺序，实现新旧交替
        newQuestions.shuffle()
        questionQueue.append(contentsOf: newQuestions)
    }

    // 设置第一个问题
    private func setupFirstQuestion() {
        // 这个方法保留为兼容，实际使用 initializeLearning
        initializeLearning()
    }

    // 设置当前问题
    private func setupCurrentQuestion() {
        guard let question = currentQuestion,
            question.wordIndex < words.count
        else { return }

        // 根据题型准备选项
        switch question.questionType {
        case .russianToChineseMultipleChoice, .russianToChineseListening:
            // 看俄选汉、听俄选汉：选项为中文
            prepareChineseOptions()
        case .chineseToRussianMultipleChoice:
            // 看汉选俄：选项为俄文
            prepareRussianOptions()
        case .chineseToRussianSpelling:
            // 看汉拼俄：清空输入
            inputText = ""
        }

        // 重置答题状态
        selectedAnswer = nil
        showResult = false
        showDetailView = false
        isCorrect = false
        showCorrectEffect = false
        showIncorrectEffect = false
        correctEffectOpacity = 0.0
        incorrectEffectOpacity = 0.0
    }

    // 准备中文选项（看俄选汉、听俄选汉）
    private func prepareChineseOptions() {
        let word = currentWord
        var optionsList = [word.chinese]

        // 从其他单词中随机选择3个错误选项
        let otherWords = words.filter { $0.id != word.id }
        let randomWords = Array(otherWords.shuffled().prefix(3))

        // 如果其他单词不够3个，从WordManager中获取更多单词
        if randomWords.count < 3 {
            let allWords = wordManager.words.filter { $0.id != word.id }
            let additionalWords = Array(allWords.shuffled().prefix(3 - randomWords.count))
            optionsList.append(contentsOf: randomWords.map { $0.chinese })
            optionsList.append(contentsOf: additionalWords.map { $0.chinese })
        } else {
            optionsList.append(contentsOf: randomWords.map { $0.chinese })
        }

        // 打乱选项顺序
        optionsList.shuffle()
        options = optionsList

        // 找到正确答案的索引
        correctAnswerIndex = options.firstIndex(of: word.chinese) ?? 0
    }

    // 准备俄文选项（看汉选俄）
    private func prepareRussianOptions() {
        let word = currentWord
        var optionsList = [word.russian]

        // 从其他单词中随机选择3个错误选项
        let otherWords = words.filter { $0.id != word.id }
        let randomWords = Array(otherWords.shuffled().prefix(3))

        // 如果其他单词不够3个，从WordManager中获取更多单词
        if randomWords.count < 3 {
            let allWords = wordManager.words.filter { $0.id != word.id }
            let additionalWords = Array(allWords.shuffled().prefix(3 - randomWords.count))
            optionsList.append(contentsOf: randomWords.map { $0.russian })
            optionsList.append(contentsOf: additionalWords.map { $0.russian })
        } else {
            optionsList.append(contentsOf: randomWords.map { $0.russian })
        }

        // 打乱选项顺序
        optionsList.shuffle()
        options = optionsList

        // 找到正确答案的索引
        correctAnswerIndex = options.firstIndex(of: word.russian) ?? 0
    }

    // 背景视图
    private var backgroundView: some View {
        LinearGradient(
            colors: wordManager.isDarkMode
                ? [Color.black.opacity(0.9), Color.blue.opacity(0.4)]
                : [Color.blue.opacity(0.05), Color.white.opacity(0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // 顶部导航栏
    private var topNavigationBar: some View {
        HStack(alignment: .center) {
            // 退出按钮 - 改为灰色的叉，与卡片左边缘对齐
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.gray.opacity(0.1)))
            }
            .padding(.leading, 20)  // 与卡片左边缘对齐

            Spacer()

            // 进度条 - 与退出按钮中心对齐
            ZStack(alignment: .leading) {
                // 背景条
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 12)

                // 已完成部分 - 确保始终在圆角矩形内，最小宽度为12保持圆角
                let progressWidth: CGFloat = max(
                    12,
                    min(200, CGFloat(completedQuestionsCount) / CGFloat(totalQuestionsCount) * 200))
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green)
                    .frame(width: progressWidth, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 6))  // 确保超出部分被裁剪
                    .animation(.easeInOut(duration: 0.3), value: completedQuestionsCount)

                // 进度高光动画
                if showProgressHighlight {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.8), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40, height: 12)
                        .offset(x: progressHighlightOffset)
                        .animation(.easeInOut(duration: 0.6), value: progressHighlightOffset)
                        .clipShape(RoundedRectangle(cornerRadius: 6))  // 确保高光也在圆角内
                }
            }
            .shadow(
                color: showCorrectEffect
                    ? Color.green.opacity(1.0)
                    : (showIncorrectEffect ? Color.red.opacity(1.0) : Color.clear),
                radius: showCorrectEffect || showIncorrectEffect ? 20 : 0,
                x: 0, y: 0
            )
            .shadow(
                color: showCorrectEffect
                    ? Color.green.opacity(0.6)
                    : (showIncorrectEffect ? Color.red.opacity(0.6) : Color.clear),
                radius: showCorrectEffect || showIncorrectEffect ? 35 : 0,
                x: 0, y: 0
            )
            .animation(.easeOut(duration: 0.6), value: showCorrectEffect)
            .animation(.easeOut(duration: 0.8), value: showIncorrectEffect)

            Spacer()

            // 右侧占位，保持退出按钮和进度条居中对称
            Rectangle()
                .fill(Color.clear)
                .frame(width: 32, height: 32)
                .padding(.trailing, 20)
        }
        .padding(.horizontal)
    }

    // 学习内容区域
    private func wordCardStack(geometry: GeometryProxy) -> some View {
        ZStack {
            // 当前学习内容
            currentWordCard(geometry: geometry)
                .offset(cardOffset)
                .rotationEffect(.degrees(cardRotation))
                .opacity(showNextCard ? 0 : 1)
                .animation(.easeInOut(duration: 0.1), value: cardOffset)
                .animation(.easeInOut(duration: 0.1), value: cardRotation)
                .animation(.easeInOut(duration: 0.075), value: showNextCard)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // 占满可用空间
    }

    // 当前学习内容（无卡片样式）
    private func currentWordCard(geometry: GeometryProxy) -> some View {
        let word = currentWord

        return VStack(spacing: 0) {
            // 顶部单词区域 - 统一位置和样式
            wordDisplaySection(for: word)
                .frame(height: 120)
                .padding(.top, 40)  // 距离顶部导航栏的距离

            Spacer(minLength: 20)

            // 中间内容区域
            if showDetailView {
                // 详细信息内容
                detailContentSection(for: word)
            } else {
                // 答题内容
                questionContentSection(for: word)
            }

            Spacer(minLength: 30)

            // 底部动作按钮
            actionButton()
                .padding(.horizontal, 20)
                .padding(.bottom, 40)  // 距离底部的安全距离
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // 初始化时播放第一个卡片的发音
            playAutoSoundIfNeeded()
        }
        .onChange(of: currentQuestion) { newQuestion in
            // 当前问题变化时，播放新卡片的发音
            playAutoSoundIfNeeded()
        }
    }

    // Adjusted 'wordDisplaySection' to ensure all return statements have matching underlying types.
    private func wordDisplaySection(for word: Word) -> some View {
        let questionType: QuestionType = currentQuestionType
        return Group {
            switch questionType {
            case .chineseToRussianMultipleChoice, .chineseToRussianSpelling:
                HStack(spacing: 16) {
                    Spacer().frame(width: 38)
                    Text(word.chinese)
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 20)
            default:
                HStack(spacing: 16) {
                    Button(action: {
                        audioManager.speak(text: word.russian)
                    }) {
                        Image(
                            systemName: audioManager.isSpeaking
                                ? "speaker.wave.2.fill" : "speaker.2.fill"
                        )
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                        .opacity(audioManager.isSpeaking ? 0.7 : 1.0)
                    }
                    Text(word.russian)
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // 答题内容区域
    private func questionContentSection(for word: Word) -> some View {
        VStack(spacing: 20) {
            // 根据题型显示不同的内容
            switch currentQuestionType {
            case .russianToChineseMultipleChoice:
                // 看俄选汉：只显示选择题
                multipleChoiceView()

            case .russianToChineseListening:
                // 听俄选汉：只显示选择题（单词已在上方统一显示）
                multipleChoiceView()

            case .chineseToRussianMultipleChoice:
                // 看汉选俄：显示中文释义和选择题
                VStack(spacing: 20) {
                    Text(word.chinese)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    multipleChoiceView()
                }

            case .chineseToRussianSpelling:
                // 看汉拼俄：显示输入框和中文释义
                VStack(spacing: 20) {
                    // 横线样式输入框（与俄语单词字体一致）
                    VStack(spacing: 4) {
                        TextField("", text: $inputText)
                            .font(.system(size: 42, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .disabled(showResult)
                            .opacity(showResult ? 0.7 : 1.0)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 20)

                        // 横线
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 2)
                            .padding(.horizontal, 40)
                    }

                    // 中文释义
                    Text(word.chinese)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // 结果显示
                    if showResult {
                        VStack(spacing: 12) {
                            if isCorrect {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 20))
                                    Text("正确！")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.green)
                                }
                            } else {
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 20))
                                        Text("答案：\(word.russian)")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // 详细信息内容区域
    private func detailContentSection(for word: Word) -> some View {
        VStack(spacing: 25) {
            // 中文释义 - 加上词性
            HStack {
                Text("\(word.partOfSpeech) \(word.chinese)")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, 20)

            // 例句区域
            VStack(spacing: 20) {
                ForEach(word.examples.prefix(2), id: \.self) { example in
                    exampleView(example: example)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // 动作按钮（不知道/确认/下一个）
    private func actionButton() -> some View {
        let buttonText: String
        let textColor: Color
        let backgroundColor: Color
        let borderColor: Color?

        if showDetailView {
            buttonText = "下一个"
            textColor = .white
            backgroundColor = .green
            borderColor = nil
        } else if currentQuestionType == .chineseToRussianSpelling && !inputText.isEmpty {
            buttonText = "确认"
            textColor = .white
            backgroundColor = .blue
            borderColor = nil
        } else {
            buttonText = "不知道"
            textColor = .red
            backgroundColor = .clear
            borderColor = .red
        }

        return Button(action: {
            if showDetailView {
                // 详情页面，点击下一个
                nextQuestion()
            } else if currentQuestionType == .chineseToRussianSpelling && !inputText.isEmpty {
                // 拼写题有输入时，点击确认
                checkSpellingAnswer()
            } else {
                // 答题页面，点击不知道
                selectDontKnow()
            }
        }) {
            Text(buttonText)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(backgroundColor)
                        .overlay(
                            borderColor != nil
                                ? RoundedRectangle(cornerRadius: 15)
                                    .stroke(borderColor!, lineWidth: 2) : nil
                        )
                )
        }
        // 移除不必要的禁用逻辑，确保按钮始终可见和可用
    }

    // 例句视图 - 俄中分行，完全左对齐，去除圆角矩形包裹
    private func exampleView(example: String) -> some View {
        let parts = example.components(separatedBy: " - ")
        let russianPart = parts.first ?? ""
        let chinesePart = parts.count > 1 ? parts[1] : ""

        return VStack(alignment: .leading, spacing: 0) {
            // 俄语例句行
            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    // 预留例句发音功能
                    audioManager.speak(text: russianPart)
                }) {
                    Image(systemName: "speaker.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
                .padding(.top, 2)  // 稍微调整喇叭按钮位置

                Text(russianPart)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)  // 允许多行显示
                    .fixedSize(horizontal: false, vertical: true)  // 确保文字可以换行

                Spacer()
            }
            .padding(.bottom, 8)

            // 中文翻译行 - 与俄文完全左对齐
            HStack(alignment: .top, spacing: 12) {
                // 透明占位符，与喇叭按钮保持一致的空间
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 16, height: 16)

                Text(chinesePart)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)  // 允许多行显示
                    .fixedSize(horizontal: false, vertical: true)  // 确保文字可以换行

                Spacer()
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
    }

    // 选项按钮
    private func optionButton(text: String, index: Int) -> some View {
        Button(action: {
            selectAnswer(index)
        }) {
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(buttonTextColor(for: index))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(buttonBorderColor(for: index), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(buttonBackgroundColor(for: index))
                        )
                )
        }
        .disabled(showResult)
    }

    // 按钮文字颜色
    private func buttonTextColor(for index: Int) -> Color {
        if !showResult {
            return .primary
        }

        if index == correctAnswerIndex {
            return .green
        } else if selectedAnswer == index && index != correctAnswerIndex {
            return .red
        } else if selectedAnswer == nil && index == correctAnswerIndex {
            // 点击"不认识"时，显示正确答案
            return .green
        }
        return .primary
    }

    // 按钮边框颜色
    private func buttonBorderColor(for index: Int) -> Color {
        if !showResult {
            return .gray.opacity(0.3)
        }

        if index == correctAnswerIndex {
            return .green
        } else if selectedAnswer == index && index != correctAnswerIndex {
            return .red
        } else if selectedAnswer == nil && index == correctAnswerIndex {
            // 点击"不认识"时，显示正确答案
            return .green
        }
        return .gray.opacity(0.3)
    }

    // 按钮背景颜色
    private func buttonBackgroundColor(for index: Int) -> Color {
        if !showResult {
            return .clear
        }

        if index == correctAnswerIndex {
            return .green.opacity(0.2)
        } else if selectedAnswer == index && index != correctAnswerIndex {
            return .red.opacity(0.2)
        } else if selectedAnswer == nil && index == correctAnswerIndex {
            // 点击"不认识"时，显示正确答案
            return .green.opacity(0.2)
        }
        return .clear
    }

    // 完成视图 - 简化的庆祝动画
    private var completionView: some View {
        VStack(spacing: 30) {
            // 庆祝图标 - 从小到大放大
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .scaleEffect(celebrationScale)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: celebrationScale)

            VStack(spacing: 12) {
                Text("恭喜完成本组学习！")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("你已经掌握了 \(words.count) 个新单词")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                // 分享成就按钮 - 金色
                Button(action: {
                    shareProgress()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                        Text("分享成就")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.orange)
                    .cornerRadius(15)
                }

                // 再学一组按钮 - 绿色填充，前面加旋转标志
                Button(action: {
                    startNewRound()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .rotationEffect(.degrees(rotateIconAngle))
                            .animation(
                                .linear(duration: 2).repeatForever(autoreverses: false),
                                value: rotateIconAngle)
                        Text("再学一组")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.green)
                    .cornerRadius(15)
                }

                // 返回首页按钮 - 次要按钮
                Button("返回首页") {
                    isPresented = false
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
            .frame(maxWidth: 280)
        }
        .onAppear {
            // 播放获胜音效（激昂音效）
            audioManager.playVictory()

            // 开始旋转动画
            rotateIconAngle = 360

            // 从小瞬间放大到正常大小，营造庆祝效果
            celebrationScale = 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    celebrationScale = 1.2
                }
            }
        }
    }

    // 庆祝动画相关状态
    @State private var celebrationScale: CGFloat = 1.0
    @State private var rotateIconAngle: Double = 0  // 旋转标志的角度

    // 加载单词
    private func loadWords() {
        switch mode {
        case .review:
            words = Array(wordManager.getWordsForReview().prefix(5))  // 限制为5个单词
            // 如果没有复习词汇，获取一些已学习的单词重新复习
            if words.isEmpty {
                words = Array(wordManager.words.shuffled().prefix(5))
            }
        case .newWords:
            words = Array(wordManager.getNewWordsForToday().prefix(5))  // 限制为5个单词
            // 如果没有新单词，从所有单词中随机选择一些来学习
            if words.isEmpty {
                let allWords = wordManager.words
                words = Array(allWords.shuffled().prefix(5))
            }
        }

        // 确保至少有一个单词
        if words.isEmpty {
            // 如果WordManager中完全没有单词，创建一些示例单词
            words = [
                Word(
                    russian: "привет", chinese: "你好", pronunciation: "pri-VYET",
                    examples: ["Привет, как дела? - 你好，怎么样？"], partOfSpeech: "междом."),
                Word(
                    russian: "спасибо", chinese: "谢谢", pronunciation: "spa-SEE-ba",
                    examples: ["Спасибо за помощь! - 谢谢你的帮助！"], partOfSpeech: "нареч."),
                Word(
                    russian: "пока", chinese: "再见", pronunciation: "pa-KA",
                    examples: ["Пока, увидимся завтра! - 再见，明天见！"], partOfSpeech: "междом."),
                Word(
                    russian: "да", chinese: "是", pronunciation: "da",
                    examples: ["Да, конечно! - 是的，当然！"], partOfSpeech: "част."),
                Word(
                    russian: "нет", chinese: "不", pronunciation: "nyet",
                    examples: ["Нет, не хочу. - 不，我不想。"], partOfSpeech: "част."),
            ]
        }

        // 记录原始单词数量
        originalWordsCount = words.count
    }

    // 选择答案
    private func selectAnswer(_ index: Int) {
        selectedAnswer = index
        isCorrect = index == correctAnswerIndex

        // 直接显示结果，无动画
        showResult = true
        processAnswer()
    }

    // 检查拼写答案
    private func checkSpellingAnswer() {
        isCorrect =
            inputText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            == currentWord.russian.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        showResult = true
        processAnswer()
    }

    // 处理答案结果
    private func processAnswer() {
        guard let question = currentQuestion else { return }

        if isCorrect {
            // 如果答对了，触发绿光效果、音效，并立即更新进度
            showCorrectEffect = true
            correctEffectOpacity = 0.4  // 从最亮开始
            audioManager.playSuccess()  // 播放成功音效

            // 标记当前题型为完成
            if question.wordIndex < wordStates.count {
                wordStates[question.wordIndex].completedTypes.insert(question.questionType)
                wordStates[question.wordIndex].incorrectTypes.remove(question.questionType)
            }

            completedQuestionsCount += 1

            // 触发进度条高光动画
            triggerProgressHighlight()

            // 光效从最亮到暗
            withAnimation(.easeOut(duration: 0.6)) {
                correctEffectOpacity = 0.0
            }

            // 0.6秒后关闭绿光效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showCorrectEffect = false
            }

            // 统一显示详细信息
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showDetailView = true
                // 再次播放发音
                audioManager.speak(text: currentWord.russian)
            }
        } else {
            // 如果答错了，触发红光效果和错误音效
            showIncorrectEffect = true
            incorrectEffectOpacity = 0.8  // 从最亮开始
            audioManager.playError()  // 播放错误音效

            // 标记当前题型为错误，需要重做
            if question.wordIndex < wordStates.count {
                wordStates[question.wordIndex].incorrectTypes.insert(question.questionType)
            }

            // 光效从最亮到暗
            withAnimation(.easeOut(duration: 0.8)) {
                incorrectEffectOpacity = 0.0
            }

            // 0.8秒后关闭红光效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showIncorrectEffect = false
            }

            // 答错时延迟1秒再显示详细信息
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showDetailView = true
                // 再次播放发音
                audioManager.speak(text: currentWord.russian)
            }
        }
    }

    // 触发进度条高光动画
    private func triggerProgressHighlight() {
        showProgressHighlight = true
        progressHighlightOffset = -50  // 从左边开始

        // 计算当前进度条的实际长度
        let currentProgressWidth = max(
            12, min(200, CGFloat(completedQuestionsCount) / CGFloat(totalQuestionsCount) * 200))

        withAnimation(.easeInOut(duration: 0.6)) {
            progressHighlightOffset = currentProgressWidth - 40  // 移动到当前进度的右边
        }

        // 动画结束后隐藏高光
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showProgressHighlight = false
        }
    }

    // 选择不知道
    private func selectDontKnow() {
        guard let question = currentQuestion else { return }

        selectedAnswer = nil
        isCorrect = false

        // 直接显示结果，无动画
        showResult = true

        // 触发红光效果和错误音效
        showIncorrectEffect = true
        incorrectEffectOpacity = 0.8  // 从最亮开始
        audioManager.playError()  // 播放错误音效

        // 标记当前题型为错误，需要重做
        if question.wordIndex < wordStates.count {
            wordStates[question.wordIndex].incorrectTypes.insert(question.questionType)
        }

        // 光效从最亮到暗
        withAnimation(.easeOut(duration: 0.8)) {
            incorrectEffectOpacity = 0.0
        }

        // 0.8秒后关闭红光效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showIncorrectEffect = false
        }

        // 延迟1秒显示详细信息
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showDetailView = true
            // 再次播放发音
            audioManager.speak(text: currentWord.russian)
        }
    }

    // 下一个问题
    private func nextQuestion() {
        withAnimation(.easeInOut(duration: 0.125)) {
            cardOffset = CGSize(width: 0, height: 600)
            showNextCard = true
        }

        // 移动到下一个问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
            moveToNextQuestion()

            // 重置动画相关状态
            cardOffset = .zero
            cardRotation = 0
            showNextCard = false
            showCorrectEffect = false
            showIncorrectEffect = false
            correctEffectOpacity = 0.0
            incorrectEffectOpacity = 0.0

            // 设置新问题
            setupCurrentQuestion()
        }
    }

    // 移动到下一个问题
    private func moveToNextQuestion() {
        // 如果题目队列为空，生成新的题目
        if questionQueue.isEmpty {
            generateNextQuestions()
        }

        // 从队列中取出下一题
        if !questionQueue.isEmpty {
            currentQuestion = questionQueue.removeFirst()
        } else {
            // 如果队列仍为空，说明所有题目都已完成
            currentQuestion = nil
        }
    }

    // 开始新一轮学习
    private func startNewRound() {
        // 重新加载单词（现在loadWords确保总是有单词可用）
        loadWords()

        // 重置学习状态
        completedQuestionsCount = 0
        selectedAnswer = nil
        showResult = false
        showDetailView = false
        isCorrect = false
        cardOffset = .zero
        cardRotation = 0
        showNextCard = false
        showCorrectEffect = false
        showIncorrectEffect = false
        correctEffectOpacity = 0.0
        incorrectEffectOpacity = 0.0
        questionQueue = []
        currentQuestion = nil

        // 重置庆祝动画状态
        celebrationScale = 1.0
        rotateIconAngle = 0

        // 重置进度条高光
        showProgressHighlight = false
        progressHighlightOffset = 0

        // 重新初始化学习
        initializeLearning()
    }

    // 分享学习进度
    private func shareProgress() {
        let shareText = "我刚刚在俄语背单词App中完成了\(words.count)个单词的学习！一起来学习吧！"

        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // 获取当前场景的窗口
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }

    // 根据题型自动播放发音
    private func playAutoSoundIfNeeded() {
        // 只在答题页面自动播放，详情页面不播放
        guard !showDetailView else { return }

        // 根据题型决定是否发音
        if currentQuestionType == .russianToChineseListening
            || currentQuestionType == .russianToChineseMultipleChoice
        {
            // 听俄选汉和看俄选汉题型，自动播放发音
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                audioManager.speak(text: currentWord.russian)
            }
        }
    }

    // 选择题视图
    private func multipleChoiceView() -> some View {
        VStack(spacing: 16) {
            ForEach(0..<options.count, id: \.self) { index in
                optionButton(text: options[index], index: index)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    LearningView(
        wordManager: WordManager(),
        mode: .newWords,
        isPresented: .constant(true)
    )
}
