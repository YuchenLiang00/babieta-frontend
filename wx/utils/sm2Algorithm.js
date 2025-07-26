/**
 * SM-2 遗忘曲线算法实现
 * 基于SuperMemo 2算法，用于计算单词的复习间隔
 */

class SM2Algorithm {
  constructor() {
    this.INITIAL_INTERVAL = 1; // 首次学习后1天复习
    this.SECOND_INTERVAL = 6;  // 第二次学习后6天复习
    this.MIN_EASINESS_FACTOR = 1.3; // 最小难度因子
    this.DEFAULT_EASINESS_FACTOR = 2.5; // 默认难度因子
  }

  /**
   * 计算下一次复习时间
   * @param {Object} wordStats - 单词统计信息
   * @param {number} quality - 答题质量 (0-5)
   * @returns {Object} 更新后的单词统计信息
   */
  calculateNext(wordStats, quality) {
    const stats = { ...wordStats };
    
    // 如果答题质量不及格 (< 3)，重新开始
    if (quality < 3) {
      stats.repetitions = 0;
      stats.interval = this.INITIAL_INTERVAL;
      stats.nextReviewDate = this.addDays(new Date(), this.INITIAL_INTERVAL);
      return stats;
    }

    // 更新难度因子
    stats.easinessFactor = Math.max(
      this.MIN_EASINESS_FACTOR,
      stats.easinessFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    );

    // 增加重复次数
    stats.repetitions += 1;

    // 计算下一次复习间隔
    if (stats.repetitions === 1) {
      stats.interval = this.INITIAL_INTERVAL;
    } else if (stats.repetitions === 2) {
      stats.interval = this.SECOND_INTERVAL;
    } else {
      stats.interval = Math.round(stats.interval * stats.easinessFactor);
    }

    // 设置下次复习日期
    stats.nextReviewDate = this.addDays(new Date(), stats.interval);
    stats.lastReviewDate = new Date();

    return stats;
  }

  /**
   * 初始化新单词的统计信息
   * @param {string} wordId - 单词ID
   * @returns {Object} 新单词的统计信息
   */
  initializeWordStats(wordId) {
    return {
      wordId,
      repetitions: 0,
      interval: this.INITIAL_INTERVAL,
      easinessFactor: this.DEFAULT_EASINESS_FACTOR,
      nextReviewDate: this.addDays(new Date(), this.INITIAL_INTERVAL),
      lastReviewDate: new Date(),
      totalReviews: 0,
      correctAnswers: 0,
      isLearned: false
    };
  }

  /**
   * 获取今天需要复习的单词
   * @param {Array} allWordStats - 所有单词的统计信息
   * @returns {Array} 今天需要复习的单词ID列表
   */
  getTodayReviewWords(allWordStats) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return allWordStats.filter(stats => {
      const reviewDate = new Date(stats.nextReviewDate);
      reviewDate.setHours(0, 0, 0, 0);
      return reviewDate <= today;
    });
  }

  /**
   * 根据用户设置获取新单词
   * @param {Array} allWords - 所有单词
   * @param {Array} learnedWordIds - 已学单词ID列表
   * @param {number} dailyNewWordsCount - 每日新词数量
   * @returns {Array} 今天要学习的新单词
   */
  getTodayNewWords(allWords, learnedWordIds, dailyNewWordsCount) {
    const unlearnedWords = allWords.filter(word => !learnedWordIds.includes(word.id));
    return unlearnedWords.slice(0, dailyNewWordsCount);
  }

  /**
   * 添加天数到日期
   * @param {Date} date - 基准日期
   * @param {number} days - 要添加的天数
   * @returns {Date} 新日期
   */
  addDays(date, days) {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
  }

  /**
   * 计算单词的掌握程度
   * @param {Object} wordStats - 单词统计信息
   * @returns {number} 掌握程度 (0-100)
   */
  calculateMasteryLevel(wordStats) {
    const { totalReviews, correctAnswers, repetitions } = wordStats;
    
    if (totalReviews === 0) return 0;
    
    const accuracyRate = correctAnswers / totalReviews;
    const stabilityBonus = Math.min(repetitions * 10, 50);
    
    return Math.min(Math.round(accuracyRate * 50 + stabilityBonus), 100);
  }

  /**
   * 判断单词是否已经掌握
   * @param {Object} wordStats - 单词统计信息
   * @returns {boolean} 是否已掌握
   */
  isWordMastered(wordStats) {
    return wordStats.repetitions >= 5 && 
           wordStats.correctAnswers / wordStats.totalReviews >= 0.8 &&
           wordStats.interval >= 30; // 间隔超过30天
  }
}

module.exports = new SM2Algorithm();
