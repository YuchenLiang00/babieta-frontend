/**
 * 数据管理器
 * 负责管理单词数据、学习进度、用户设置等
 */

const sm2Algorithm = require('./sm2Algorithm');

class DataManager {
  constructor() {
    this.STORAGE_KEYS = {
      WORD_STATS: 'word_stats',
      USER_SETTINGS: 'user_settings',
      DAILY_PROGRESS: 'daily_progress',
      LEARNED_WORDS: 'learned_words'
    };
  }

  /**
   * 获取所有单词统计信息
   * @returns {Array} 单词统计信息数组
   */
  getWordStats() {
    try {
      const stats = wx.getStorageSync(this.STORAGE_KEYS.WORD_STATS);
      return stats || [];
    } catch (error) {
      console.log('获取单词统计信息失败(可能是游客模式):', error);
      return []; // 游客模式下返回空数组
    }
  }

  /**
   * 保存单词统计信息
   * @param {Array} wordStats - 单词统计信息数组
   */
  saveWordStats(wordStats) {
    try {
      wx.setStorageSync(this.STORAGE_KEYS.WORD_STATS, wordStats);
    } catch (error) {
      console.log('保存单词统计信息失败(可能是游客模式):', error);
      // 游客模式下忽略保存错误
    }
  }

  /**
   * 更新单词统计信息
   * @param {string} wordId - 单词ID
   * @param {number} quality - 答题质量 (0-5)
   * @returns {Object} 更新后的统计信息
   */
  updateWordStats(wordId, quality) {
    const allStats = this.getWordStats();
    let wordStats = allStats.find(stats => stats.wordId === wordId);

    if (!wordStats) {
      wordStats = sm2Algorithm.initializeWordStats(wordId);
      allStats.push(wordStats);
    }

    // 更新统计信息
    wordStats.totalReviews += 1;
    if (quality >= 3) {
      wordStats.correctAnswers += 1;
    }

    // 使用SM-2算法计算下次复习时间
    const updatedStats = sm2Algorithm.calculateNext(wordStats, quality);
    
    // 更新数组中的统计信息
    const index = allStats.findIndex(stats => stats.wordId === wordId);
    if (index !== -1) {
      allStats[index] = updatedStats;
    }

    // 保存到本地存储
    this.saveWordStats(allStats);

    return updatedStats;
  }

  /**
   * 获取今天的学习计划
   * @returns {Object} 今天的学习计划
   */
  getTodayPlan() {
    const userSettings = this.getUserSettings();
    const dailyNewWords = userSettings.dailyNewWords || 10;
    const allWords = this.getAllWords();
    const allWordStats = this.getWordStats();

    // 获取今天需要复习的单词
    const reviewWords = sm2Algorithm.getTodayReviewWords(allWordStats);
    
    // 获取已学习的单词ID
    const learnedWordIds = allWordStats.map(stats => stats.wordId);
    
    // 获取今天的新单词
    const newWords = sm2Algorithm.getTodayNewWords(allWords, learnedWordIds, dailyNewWords);

    console.log('数据管理器 - 复习单词数量:', reviewWords.length);
    console.log('数据管理器 - 新单词数量:', newWords.length);

    return {
      reviewWords: reviewWords.length,
      newWords: newWords.length,
      totalWords: reviewWords.length + newWords.length,
      words: {
        review: reviewWords,
        new: newWords
      }
    };
  }

  /**
   * 获取用户设置
   * @returns {Object} 用户设置
   */
  getUserSettings() {
    try {
      const settings = wx.getStorageSync(this.STORAGE_KEYS.USER_SETTINGS);
      return settings || this.getDefaultSettings();
    } catch (error) {
      console.error('获取用户设置失败:', error);
      return this.getDefaultSettings();
    }
  }

  /**
   * 保存用户设置
   * @param {Object} settings - 用户设置
   */
  saveUserSettings(settings) {
    try {
      wx.setStorageSync(this.STORAGE_KEYS.USER_SETTINGS, settings);
    } catch (error) {
      console.error('保存用户设置失败:', error);
    }
  }

  /**
   * 获取默认设置
   * @returns {Object} 默认设置
   */
  getDefaultSettings() {
    return {
      dailyNewWords: 10,
      reviewMode: 'mixed', // mixed, review_first, new_first
      autoPlayPronunciation: true,
      backgroundMusic: false,
      theme: 'light', // light, dark, auto
      fontSize: 18,
      bgStyle: 0, // 背景样式索引
      sunsetMode: false
    };
  }

  /**
   * 获取今日学习进度
   * @returns {Object} 今日学习进度
   */
  getTodayProgress() {
    const today = this.getTodayDateString();
    try {
      const progress = wx.getStorageSync(this.STORAGE_KEYS.DAILY_PROGRESS);
      return progress && progress[today] || {
        date: today,
        learnedWords: 0,
        reviewWords: 0,
        totalWords: 0,
        accuracy: 0,
        studyTime: 0 // 学习时间（分钟）
      };
    } catch (error) {
      console.error('获取今日进度失败:', error);
      return {
        date: today,
        learnedWords: 0,
        reviewWords: 0,
        totalWords: 0,
        accuracy: 0,
        studyTime: 0
      };
    }
  }

  /**
   * 更新今日学习进度
   * @param {Object} progress - 进度信息
   */
  updateTodayProgress(progress) {
    const today = this.getTodayDateString();
    try {
      let allProgress = wx.getStorageSync(this.STORAGE_KEYS.DAILY_PROGRESS) || {};
      allProgress[today] = { ...allProgress[today], ...progress, date: today };
      wx.setStorageSync(this.STORAGE_KEYS.DAILY_PROGRESS, allProgress);
    } catch (error) {
      console.error('更新今日进度失败:', error);
    }
  }

  /**
   * 获取所有单词数据
   * @returns {Array} 所有单词数组
   */
  getAllWords() {
    // 这里应该从单词库中获取所有单词
    // 目前使用硬编码的示例数据
    return [
      { 
        id: 'privet', 
        word: 'Привет', 
        translation: '你好', 
        pronunciation: 'privet',
        example: 'Привет, как дела?',
        exampleTranslation: '你好，你怎么样？',
        audioUrl: '/assets/audio/privet.mp3',
        tags: ['greeting', 'basic'],
        difficulty: 1
      },
      { 
        id: 'spasibo', 
        word: 'Спасибо', 
        translation: '谢谢', 
        pronunciation: 'spasibo',
        example: 'Спасибо за помощь!',
        exampleTranslation: '谢谢你的帮助！',
        audioUrl: '/assets/audio/spasibo.mp3',
        tags: ['greeting', 'basic'],
        difficulty: 1
      },
      { 
        id: 'pozhaluysta', 
        word: 'Пожалуйста', 
        translation: '请，不客气', 
        pronunciation: 'pozhaluysta',
        example: 'Пожалуйста, помогите мне.',
        exampleTranslation: '请帮助我。',
        audioUrl: '/assets/audio/pozhaluysta.mp3',
        tags: ['greeting', 'basic'],
        difficulty: 2
      },
      { 
        id: 'izvinite', 
        word: 'Извините', 
        translation: '对不起，打扰一下', 
        pronunciation: 'izvinite',
        example: 'Извините за опоздание.',
        exampleTranslation: '对不起迟到了。',
        audioUrl: '/assets/audio/izvinite.mp3',
        tags: ['greeting', 'basic'],
        difficulty: 2
      },
      { 
        id: 'da', 
        word: 'Да', 
        translation: '是的', 
        pronunciation: 'da',
        example: 'Да, это правильно.',
        exampleTranslation: '是的，这是正确的。',
        audioUrl: '/assets/audio/da.mp3',
        tags: ['basic', 'response'],
        difficulty: 1
      },
      { 
        id: 'net', 
        word: 'Нет', 
        translation: '不是', 
        pronunciation: 'net',
        example: 'Нет, это неправильно.',
        exampleTranslation: '不，这是错误的。',
        audioUrl: '/assets/audio/net.mp3',
        tags: ['basic', 'response'],
        difficulty: 1
      },
      { 
        id: 'ya', 
        word: 'Я', 
        translation: '我', 
        pronunciation: 'ya',
        example: 'Я изучаю русский язык.',
        exampleTranslation: '我在学习俄语。',
        audioUrl: '/assets/audio/ya.mp3',
        tags: ['pronoun', 'basic'],
        difficulty: 1
      },
      { 
        id: 'ty', 
        word: 'Ты', 
        translation: '你', 
        pronunciation: 'ty',
        example: 'Ты говоришь по-русски?',
        exampleTranslation: '你会说俄语吗？',
        audioUrl: '/assets/audio/ty.mp3',
        tags: ['pronoun', 'basic'],
        difficulty: 1
      },
      { 
        id: 'my', 
        word: 'Мы', 
        translation: '我们', 
        pronunciation: 'my',
        example: 'Мы идём в театр.',
        exampleTranslation: '我们去剧院。',
        audioUrl: '/assets/audio/my.mp3',
        tags: ['pronoun', 'basic'],
        difficulty: 1
      },
      { 
        id: 'oni', 
        word: 'Они', 
        translation: '他们', 
        pronunciation: 'oni',
        example: 'Они работают в офисе.',
        exampleTranslation: '他们在办公室工作。',
        audioUrl: '/assets/audio/oni.mp3',
        tags: ['pronoun', 'basic'],
        difficulty: 1
      },
      { 
        id: 'horosho', 
        word: 'Хорошо', 
        translation: '好的', 
        pronunciation: 'horosho',
        example: 'Хорошо, я понимаю.',
        exampleTranslation: '好的，我明白了。',
        audioUrl: '/assets/audio/horosho.mp3',
        tags: ['adjective', 'basic'],
        difficulty: 2
      },
      { 
        id: 'plokho', 
        word: 'Плохо', 
        translation: '不好', 
        pronunciation: 'plokho',
        example: 'Сегодня плохая погода.',
        exampleTranslation: '今天天气不好。',
        audioUrl: '/assets/audio/plokho.mp3',
        tags: ['adjective', 'basic'],
        difficulty: 2
      },
      { 
        id: 'segodnya', 
        word: 'Сегодня', 
        translation: '今天', 
        pronunciation: 'segodnya',
        example: 'Сегодня хорошая погода.',
        exampleTranslation: '今天天气很好。',
        audioUrl: '/assets/audio/segodnya.mp3',
        tags: ['time', 'basic'],
        difficulty: 2
      },
      { 
        id: 'vchera', 
        word: 'Вчера', 
        translation: '昨天', 
        pronunciation: 'vchera',
        example: 'Вчера я был дома.',
        exampleTranslation: '昨天我在家。',
        audioUrl: '/assets/audio/vchera.mp3',
        tags: ['time', 'basic'],
        difficulty: 2
      },
      { 
        id: 'zavtra', 
        word: 'Завтра', 
        translation: '明天', 
        pronunciation: 'zavtra',
        example: 'Завтра будет солнечно.',
        exampleTranslation: '明天会是晴天。',
        audioUrl: '/assets/audio/zavtra.mp3',
        tags: ['time', 'basic'],
        difficulty: 2
      }
    ];
  }

  /**
   * 获取今天的日期字符串
   * @returns {string} 日期字符串 (YYYY-MM-DD)
   */
  getTodayDateString() {
    const today = new Date();
    return today.toISOString().split('T')[0];
  }

  /**
   * 打乱数组顺序
   * @param {Array} array - 要打乱的数组
   */
  shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
  }

  /**
   * 获取学习统计信息
   * @returns {Object} 学习统计信息
   */
  getStudyStatistics() {
    const allWordStats = this.getWordStats();
    const totalWords = allWordStats.length;
    const masteredWords = allWordStats.filter(stats => 
      sm2Algorithm.isWordMastered(stats)
    ).length;
    const averageAccuracy = totalWords > 0 ? 
      allWordStats.reduce((sum, stats) => 
        sum + (stats.correctAnswers / Math.max(stats.totalReviews, 1)), 0
      ) / totalWords : 0;

    return {
      totalWords,
      masteredWords,
      averageAccuracy: Math.round(averageAccuracy * 100),
      studyDays: this.getStudyDays()
    };
  }

  /**
   * 获取学习天数
   * @returns {number} 学习天数
   */
  getStudyDays() {
    try {
      const allProgress = wx.getStorageSync(this.STORAGE_KEYS.DAILY_PROGRESS) || {};
      return Object.keys(allProgress).length;
    } catch (error) {
      console.error('获取学习天数失败:', error);
      return 0;
    }
  }
}

module.exports = new DataManager();
