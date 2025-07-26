const dataManager = require('../../utils/dataManager');
const sm2Algorithm = require('../../utils/sm2Algorithm');

Page({
  data: {
    // 游客模式标识
    isGuestMode: false,
    
    // 学习模式：'review' 复习模式, 'learn' 学习模式
    learningMode: 'learn',
    
    // 当前单词列表
    wordList: [],
    currentIndex: 0,
    totalWords: 0,
    
    // 当前单词信息
    currentWord: {},
    
    // 题目模式：'word' 看单词选释义, 'translation' 看释义选单词
    mode: 'word',
    
    // 选择题选项
    options: [],
    correctIndex: 0,
    selectedOption: -1,
    
    // 答题状态
    showResult: false,
    isCorrect: false,
    feedbackText: '',
    
    // 进度
    progressPercentage: 0,
    
    // 统计信息
    correctCount: 0,
    wrongCount: 0,
    unknownCount: 0
  },

  onLoad(options) {
    console.log('=== 学习页面加载开始 ===');
    console.log('接收到的参数:', options);
    
    // 检测运行环境
    try {
      const accountInfo = wx.getAccountInfoSync();
      console.log('学习页面 - 账户信息:', accountInfo);
      
      if (accountInfo.miniProgram && accountInfo.miniProgram.appId === 'touristappid') {
        console.log('学习页面 - 检测到游客模式');
        this.setData({ isGuestMode: true });
      }
    } catch (error) {
      console.log('学习页面 - 无法获取账户信息（可能是游客模式）:', error);
      this.setData({ isGuestMode: true });
    }
    
    // 获取学习模式
    const mode = options.mode || 'learn';
    this.setData({ learningMode: mode });

    console.log('设置学习模式为:', mode);

    // 初始化学习内容
    try {
      this.initLearningContent();
    } catch (error) {
      console.error('初始化学习内容失败:', error);
      // 如果初始化失败，使用默认数据
      this.useDefaultData();
    }
  },

  /**
   * 使用默认数据（游客模式备用方案）
   */
  useDefaultData() {
    console.log('使用默认测试数据');
    const defaultWords = [
      {
        id: 'privet',
        word: 'Привет',
        translation: '你好',
        pronunciation: 'privet'
      },
      {
        id: 'spasibo',
        word: 'Спасибо',
        translation: '谢谢',
        pronunciation: 'spasibo'
      }
    ];
    
    this.setData({
      wordList: defaultWords,
      totalWords: defaultWords.length,
      currentIndex: 0
    });
    
    this.loadCurrentWord();
  },

  /**
   * 初始化学习内容
   */
  initLearningContent() {
    const { learningMode } = this.data;
    let wordList = [];

    console.log('初始化学习内容，模式:', learningMode);

    try {
      if (learningMode === 'review') {
        // 复习模式：尝试获取需要复习的单词
        try {
          const allWordStats = dataManager.getWordStats();
          const reviewWordStats = sm2Algorithm.getTodayReviewWords(allWordStats);
          const reviewWordIds = reviewWordStats.map(stats => stats.wordId);
          wordList = this.getWordDetailsFromIds(reviewWordIds);
        } catch (err) {
          console.log('获取复习单词失败，使用默认数据:', err);
          wordList = [];
        }
      } else {
        // 学习模式：尝试获取新单词
        try {
          const allWords = dataManager.getAllWords();
          const allWordStats = dataManager.getWordStats();
          const learnedWordIds = allWordStats.map(stats => stats.wordId);
          const userSettings = dataManager.getUserSettings();
          const dailyNewWords = userSettings.dailyNewWords || 5;
          
          const newWords = sm2Algorithm.getTodayNewWords(allWords, learnedWordIds, dailyNewWords);
          wordList = newWords;
        } catch (err) {
          console.log('获取新单词失败，使用默认数据:', err);
          wordList = [];
        }
      }

      if (wordList.length === 0) {
        // 如果没有单词，使用默认测试单词
        wordList = this.getDefaultTestWords();
        console.log('使用默认测试单词:', wordList);
      }

      this.setData({
        wordList,
        totalWords: wordList.length,
        currentIndex: 0
      });

      this.loadCurrentWord();
      
    } catch (error) {
      console.error('初始化学习内容完全失败:', error);
      this.useDefaultData();
    }
  },

  /**
   * 获取默认测试单词（用于演示）
   */
  getDefaultTestWords() {
    const allWords = dataManager.getAllWords();
    return allWords.slice(0, 5); // 取前5个单词作为测试
  },

  /**
   * 根据单词ID获取详细信息
   */
  getWordDetailsFromIds(wordIds) {
    const allWords = dataManager.getAllWords();
    return wordIds.map(id => allWords.find(word => word.id === id)).filter(Boolean);
  },

  /**
   * 加载当前单词
   */
  loadCurrentWord() {
    const { wordList, currentIndex, totalWords } = this.data;
    
    if (currentIndex >= totalWords) {
      this.showCompletionPage();
      return;
    }

    const currentWord = wordList[currentIndex];
    
    // 随机决定题目模式（70%概率看单词选释义，30%看释义选单词）
    const mode = Math.random() < 0.7 ? 'word' : 'translation';
    
    // 生成选择题选项
    const { options, correctIndex } = this.generateOptions(currentWord, mode);
    
    // 计算进度
    const progressPercentage = Math.round((currentIndex / totalWords) * 100);

    this.setData({
      currentWord,
      mode,
      options,
      correctIndex,
      selectedOption: -1,
      showResult: false,
      isCorrect: false,
      feedbackText: '',
      progressPercentage
    });
  },

  /**
   * 生成选择题选项
   */
  generateOptions(correctWord, mode) {
    const allWords = dataManager.getAllWords();
    const options = [];
    let correctIndex = 0;

    // 获取正确答案
    const correctAnswer = mode === 'word' ? correctWord.translation : correctWord.word;
    
    // 获取3个干扰项
    const distractors = allWords
      .filter(word => word.id !== correctWord.id)
      .map(word => mode === 'word' ? word.translation : word.word)
      .filter(answer => answer !== correctAnswer)
      .sort(() => Math.random() - 0.5)
      .slice(0, 3);

    // 随机插入正确答案
    correctIndex = Math.floor(Math.random() * 4);
    
    for (let i = 0; i < 4; i++) {
      if (i === correctIndex) {
        options.push(correctAnswer);
      } else {
        options.push(distractors.shift());
      }
    }

    return { options, correctIndex };
  },

  /**
   * 选择选项
   */
  selectOption(e) {
    const selectedIndex = parseInt(e.currentTarget.dataset.index);
    const { correctIndex } = this.data;
    
    const isCorrect = selectedIndex === correctIndex;
    const feedbackText = isCorrect ? '回答正确！' : '回答错误，正确答案已标出';

    this.setData({
      selectedOption: selectedIndex,
      showResult: true,
      isCorrect,
      feedbackText
    });

    // 更新统计
    if (isCorrect) {
      this.setData({ correctCount: this.data.correctCount + 1 });
    } else {
      this.setData({ wrongCount: this.data.wrongCount + 1 });
    }

    // 记录学习结果
    this.recordLearningResult(isCorrect ? 4 : 2); // SM-2算法质量评分
  },

  /**
   * 标记为不认识
   */
  markUnknown() {
    const { correctIndex } = this.data;
    
    this.setData({
      selectedOption: -1,
      showResult: true,
      isCorrect: false,
      feedbackText: '正确答案已标出，请仔细记忆',
      unknownCount: this.data.unknownCount + 1
    });

    // 记录学习结果
    this.recordLearningResult(1); // SM-2算法质量评分：不认识
  },

  /**
   * 记录学习结果
   */
  recordLearningResult(quality) {
    const { currentWord } = this.data;
    
    // 使用数据管理器更新单词统计
    dataManager.updateWordStats(currentWord.id, quality);
    
    // 更新今日学习进度
    const todayProgress = dataManager.getTodayProgress();
    const updatedProgress = {
      ...todayProgress,
      totalWords: todayProgress.totalWords + 1
    };
    
    if (this.data.learningMode === 'learn') {
      updatedProgress.learnedWords = todayProgress.learnedWords + 1;
    } else {
      updatedProgress.reviewWords = todayProgress.reviewWords + 1;
    }
    
    dataManager.updateTodayProgress(updatedProgress);
  },

  /**
   * 下一个单词
   */
  nextWord() {
    const { currentIndex, totalWords, currentWord } = this.data;
    
    // 延迟跳转到详情页面，让用户看到单词的完整信息
    setTimeout(() => {
      wx.navigateTo({
        url: `/pages/word-detail/index?wordId=${currentWord.id}`
      });
    }, 1000);
    
    // 然后继续下一个单词或完成学习
    setTimeout(() => {
      if (currentIndex + 1 >= totalWords) {
        this.showCompletionPage();
      } else {
        this.setData({
          currentIndex: currentIndex + 1
        });
        this.loadCurrentWord();
      }
    }, 3000); // 给用户3秒时间查看详情页面
  },

  /**
   * 显示完成页面
   */
  showCompletionPage() {
    const { correctCount, wrongCount, unknownCount, totalWords, learningMode } = this.data;
    const accuracy = totalWords > 0 ? Math.round((correctCount / totalWords) * 100) : 0;
    
    wx.showModal({
      title: '学习完成！',
      content: `${learningMode === 'learn' ? '新词学习' : '复习'}完成！\n\n总计：${totalWords}个单词\n正确：${correctCount}个\n错误：${wrongCount}个\n不认识：${unknownCount}个\n正确率：${accuracy}%`,
      showCancel: false,
      confirmText: '返回主页',
      success: () => {
        wx.navigateBack();
      }
    });
  },

  /**
   * 播放音频
   */
  playAudio() {
    const { currentWord } = this.data;
    
    if (currentWord.audioUrl) {
      const innerAudioContext = wx.createInnerAudioContext();
      innerAudioContext.src = currentWord.audioUrl;
      innerAudioContext.play();
      
      innerAudioContext.onError((err) => {
        console.error('音频播放失败:', err);
        wx.showToast({
          title: '音频播放失败',
          icon: 'none'
        });
      });
    } else {
      wx.showToast({
        title: '暂无音频文件',
        icon: 'none'
      });
    }
  },

  /**
   * 返回上一页
   */
  goBack() {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出当前学习吗？学习进度将会保存。',
      success: (res) => {
        if (res.confirm) {
          wx.navigateBack();
        }
      }
    });
  }
});
