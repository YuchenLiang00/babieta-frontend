//
//  WordManager.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import Foundation

class WordManager: ObservableObject {
    @Published var words: [Word] = []
    @Published var dailyNewWordsTarget: Int = 20
    @Published var backgroundImageIndex: Int = 0
    @Published var isDarkMode: Bool = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let userDefaults = UserDefaults.standard
    private var userSettings: UserSettings?

    init() {
        loadWords()
        loadSettings()
        updateBackgroundImage()
    }

    // MARK: - 数据加载和保存

    // 从本地加载单词数据
    func loadWords() {
        loadLocalWords()
        isLoading = false
    }

    // 加载本地单词数据（离线模式）
    private func loadLocalWords() {
        if let data = userDefaults.data(forKey: "words"),
            let decodedWords = try? JSONDecoder().decode([Word].self, from: data)
        {
            self.words = decodedWords
        } else {
            loadSampleWords()
        }

        // 临时：强制重新加载示例单词（用于测试）
        // 注释掉下面两行可以保持学习进度
        loadSampleWords()
        resetAllWordsToNew()
    }

    // 保存单词数据
    func saveWords() {
        // 保存到本地
        if let encoded = try? JSONEncoder().encode(words) {
            userDefaults.set(encoded, forKey: "words")
        }
    }

    // 加载设置
    func loadSettings() {
        loadLocalSettings()
    }

    // 加载本地设置
    private func loadLocalSettings() {
        dailyNewWordsTarget = userDefaults.integer(forKey: "dailyNewWordsTarget")
        if dailyNewWordsTarget == 0 { dailyNewWordsTarget = 20 }

        backgroundImageIndex = userDefaults.integer(forKey: "backgroundImageIndex")
        isDarkMode = userDefaults.bool(forKey: "isDarkMode")
    }

    // 保存设置
    func saveSettings() {
        // 保存到本地
        userDefaults.set(dailyNewWordsTarget, forKey: "dailyNewWordsTarget")
        userDefaults.set(backgroundImageIndex, forKey: "backgroundImageIndex")
        userDefaults.set(isDarkMode, forKey: "isDarkMode")
    }

    // 每天更新背景图片
    private func updateBackgroundImage() {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        backgroundImageIndex = dayOfYear % 10  // 假设有10张背景图
    }

    // 获取今日需要复习的单词
    func getWordsForReview() -> [Word] {
        return words.filter { word in
            guard let nextReviewDate = word.nextReviewDate else { return false }
            return nextReviewDate <= Date() && !word.isNew
        }
    }

    // 获取今日新学单词
    func getNewWordsForToday() -> [Word] {
        let newWords = words.filter { $0.isNew }
        return Array(newWords.prefix(dailyNewWordsTarget))
    }

    // 更新单词学习状态
    func updateWordProgress(_ word: Word, isKnown: Bool) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].updateReviewSchedule(isKnown: isKnown)
        }

        saveWords()
    }

    // MARK: - 错误处理

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    // MARK: - 用户认证状态变化处理

    func handleUserSignIn() {
        loadWords()
        loadSettings()
    }

    func handleUserSignOut() {
        // 清空数据，回到本地模式
        words = []
        userSettings = nil
        loadLocalWords()
        loadLocalSettings()
    }

    // MARK: - 数据查询方法（保持不变）

    // 重置所有单词为新单词状态（用于测试）
    func resetAllWordsToNew() {
        for i in 0..<words.count {
            words[i].isNew = true
            words[i].learningLevel = 0
            words[i].lastReviewDate = nil
            words[i].nextReviewDate = nil
        }
        saveWords()
    }

    // 获取新词数量
    func getNewWordsCount() -> Int {
        return words.filter { $0.isNew }.count
    }

    // 获取已掌握的单词数量（学习等级 >= 3）
    func getMasteredWordsCount() -> Int {
        return words.filter { $0.learningLevel >= 3 }.count
    }

    // 获取需要复习的单词数量
    func getReviewWordsCount() -> Int {
        return getWordsForReview().count
    }

    // 获取学习进度百分比
    func getProgressPercentages() -> (mastered: Double, reviewing: Double, remaining: Double) {
        guard !words.isEmpty else { return (0, 0, 0) }

        let totalCount = words.count
        let masteredCount = getMasteredWordsCount()
        let reviewingCount = words.filter { !$0.isNew && $0.learningLevel < 3 }.count
        let remainingCount = getNewWordsCount()

        return (
            mastered: Double(masteredCount) / Double(totalCount),
            reviewing: Double(reviewingCount) / Double(totalCount),
            remaining: Double(remainingCount) / Double(totalCount)
        )
    }

    // 获取学习过的日期
    func getStudiedDates() -> Set<Date> {
        let calendar = Calendar.current
        return Set(
            words.compactMap { word in
                guard let date = word.lastReviewDate else { return nil }
                return calendar.startOfDay(for: date)
            })
    }

    // 加载示例俄语单词
    private func loadSampleWords() {
        let sampleWords = [
            // 基础词汇
            Word(
                russian: "дом", chinese: "房子", pronunciation: "dom",
                examples: ["Мой дом очень красивый. - 我的房子很漂亮。", "Где твой дом? - 你的房子在哪里？"],
                partOfSpeech: "сущ."),
            Word(
                russian: "любовь", chinese: "爱情", pronunciation: "lyubov'",
                examples: [
                    "Любовь - это прекрасное чувство. - 爱情是美好的感情。",
                    "Первая любовь незабываема. - 初恋是难忘的。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "жизнь", chinese: "生活", pronunciation: "zhizn'",
                examples: [
                    "Жизнь прекрасна! - 生活是美好的！", "Студенческая жизнь интересная. - 学生生活很有趣。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "работа", chinese: "工作", pronunciation: "rabota",
                examples: [
                    "Моя работа интересная. - 我的工作很有趣。", "Завтра у меня много работы. - 明天我有很多工作。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "друг", chinese: "朋友", pronunciation: "drug",
                examples: [
                    "Мой лучший друг живёт в Москве. - 我最好的朋友住在莫斯科。",
                    "Друзья помогают друг другу. - 朋友互相帮助。",
                ], partOfSpeech: "сущ."),

            // 时间和自然
            Word(
                russian: "время", chinese: "时间", pronunciation: "vremya",
                examples: ["Время летит быстро. - 时间过得很快。", "У меня нет времени. - 我没有时间。"],
                partOfSpeech: "сущ."),
            Word(
                russian: "солнце", chinese: "太阳", pronunciation: "solntse",
                examples: [
                    "Солнце светит ярко. - 太阳照得很亮。", "Летом солнце встаёт рано. - 夏天太阳升得早。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "море", chinese: "海", pronunciation: "more",
                examples: ["Я люблю море. - 我喜欢大海。", "Мы едем на море в отпуск. - 我们去海边度假。"],
                partOfSpeech: "сущ."),
            Word(
                russian: "лес", chinese: "森林", pronunciation: "les",
                examples: ["В лесу много деревьев. - 森林里有很多树。", "Мы гуляли по лесу. - 我们在森林里散步。"],
                partOfSpeech: "сущ."),
            Word(
                russian: "река", chinese: "河流", pronunciation: "reka",
                examples: ["Река течёт в море. - 河流流向大海。", "Мы купались в реке. - 我们在河里游泳。"],
                partOfSpeech: "сущ."),

            // 学习和文化
            Word(
                russian: "книга", chinese: "书", pronunciation: "kniga",
                examples: [
                    "Эта книга очень интересная. - 这本书很有趣。", "Я читаю книгу каждый день. - 我每天都读书。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "музыка", chinese: "音乐", pronunciation: "muzyka",
                examples: [
                    "Я слушаю музыку каждый день. - 我每天都听音乐。",
                    "Классическая музыка мне нравится. - 我喜欢古典音乐。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "школа", chinese: "学校", pronunciation: "shkola",
                examples: [
                    "Дети идут в школу. - 孩子们去上学。", "Моя школа находится рядом. - 我的学校就在附近。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "учитель", chinese: "老师", pronunciation: "uchitel'",
                examples: [
                    "Учитель объясняет урок. - 老师在讲课。", "Мой учитель очень добрый. - 我的老师很和善。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "студент", chinese: "学生", pronunciation: "student",
                examples: [
                    "Он студент университета. - 他是大学生。",
                    "Студенты изучают русский язык. - 学生们在学习俄语。",
                ], partOfSpeech: "сущ."),

            // 家庭和日常
            Word(
                russian: "мама", chinese: "妈妈", pronunciation: "mama",
                examples: ["Моя мама работает врачом. - 我妈妈是医生。", "Мама готовит обед. - 妈妈在做午饭。"],
                partOfSpeech: "сущ."),
            Word(
                russian: "папа", chinese: "爸爸", pronunciation: "papa",
                examples: ["Папа читает газету. - 爸爸在看报纸。", "Мой папа инженер. - 我爸爸是工程师。"],
                partOfSpeech: "сущ."),
            Word(
                russian: "семья", chinese: "家庭", pronunciation: "sem'ya",
                examples: ["У меня большая семья. - 我有一个大家庭。", "Семья очень важна. - 家庭很重要。"],
                partOfSpeech: "сущ."),
            Word(
                russian: "еда", chinese: "食物", pronunciation: "eda",
                examples: [
                    "Эта еда очень вкусная. - 这食物很好吃。", "Мама покупает еду в магазине. - 妈妈在商店买食物。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "вода", chinese: "水", pronunciation: "voda",
                examples: ["Вода очень важна для жизни. - 水对生命很重要。", "Я пью много воды. - 我喝很多水。"],
                partOfSpeech: "сущ."),

            // 城市和交通
            Word(
                russian: "город", chinese: "城市", pronunciation: "gorod",
                examples: [
                    "Москва - большой город. - 莫斯科是个大城市。", "В городе много машин. - 城市里有很多汽车。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "машина", chinese: "汽车", pronunciation: "mashina",
                examples: [
                    "У него красивая машина. - 他有一辆漂亮的汽车。", "Машина едет по дороге. - 汽车在路上行驶。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "автобус", chinese: "公交车", pronunciation: "avtobus",
                examples: [
                    "Я езжу на работу на автобусе. - 我坐公交车上班。", "Автобус опаздывает. - 公交车晚点了。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "метро", chinese: "地铁", pronunciation: "metro",
                examples: [
                    "Метро в Москве очень красивое. - 莫斯科的地铁很漂亮。",
                    "Я добираюсь на метро. - 我坐地铁出行。",
                ], partOfSpeech: "сущ."),
            Word(
                russian: "магазин", chinese: "商店", pronunciation: "magazin",
                examples: [
                    "В магазине продают продукты. - 商店里卖食品。",
                    "Этот магазин работает круглосуточно. - 这家商店24小时营业。",
                ], partOfSpeech: "сущ."),

            // 颜色和形容词
            Word(
                russian: "красный", chinese: "红色的", pronunciation: "krasnyy",
                examples: [
                    "Красное яблоко лежит на столе. - 红苹果放在桌子上。",
                    "Мне нравится красный цвет. - 我喜欢红色。",
                ], partOfSpeech: "прил."),
            Word(
                russian: "синий", chinese: "蓝色的", pronunciation: "siniy",
                examples: [
                    "Синее небо очень красивое. - 蓝色的天空很美丽。", "У него синие глаза. - 他有蓝色的眼睛。",
                ], partOfSpeech: "прил."),
            Word(
                russian: "белый", chinese: "白色的", pronunciation: "belyy",
                examples: [
                    "Белый снег покрывает землю. - 白雪覆盖大地。",
                    "Белая рубашка выглядит элегантно. - 白色衬衫看起来很优雅。",
                ], partOfSpeech: "прил."),
            Word(
                russian: "большой", chinese: "大的", pronunciation: "bol'shoy",
                examples: [
                    "Это очень большой дом. - 这是一个很大的房子。", "У него большая собака. - 他有一只大狗。",
                ], partOfSpeech: "прил."),
            Word(
                russian: "маленький", chinese: "小的", pronunciation: "malen'kiy",
                examples: [
                    "Маленький ребёнок играет. - 小孩在玩耍。", "Это маленький подарок. - 这是一个小礼物。",
                ], partOfSpeech: "прил."),

            // 动词
            Word(
                russian: "идти", chinese: "走，去", pronunciation: "idti",
                examples: ["Я иду в школу. - 我去学校。", "Дети идут домой. - 孩子们回家。"],
                partOfSpeech: "глаг."),
            Word(
                russian: "есть", chinese: "吃", pronunciation: "est'",
                examples: ["Я ем завтрак. - 我在吃早餐。", "Что ты любишь есть? - 你喜欢吃什么？"],
                partOfSpeech: "глаг."),
        ]

        self.words = sampleWords
        saveWords()
    }
}
