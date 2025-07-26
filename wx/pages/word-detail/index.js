const dataManager = require('../../utils/dataManager');
const sm2Algorithm = require('../../utils/sm2Algorithm');

Page({
  data: {
    wordInfo: {},
    wordStats: null,
    isFavorite: false,
    accuracy: 0,
    masteryLevel: 0,
    nextReviewDateText: ''
  },

  onLoad(options) {
    const wordId = options.wordId;
    if (wordId) {
      this.loadWordDetail(wordId);
    } else {
      wx.showToast({
        title: '参数错误',
        icon: 'none'
      });
      setTimeout(() => {
        wx.navigateBack();
      }, 1500);
    }
  },

  /**
   * 加载单词详情
   */
  loadWordDetail(wordId) {
    // 获取单词基本信息
    const allWords = dataManager.getAllWords();
    const wordInfo = allWords.find(word => word.id === wordId);
    
    if (!wordInfo) {
      wx.showToast({
        title: '单词不存在',
        icon: 'none'
      });
      setTimeout(() => {
        wx.navigateBack();
      }, 1500);
      return;
    }

    // 获取单词学习统计
    const allWordStats = dataManager.getWordStats();
    const wordStats = allWordStats.find(stats => stats.wordId === wordId);

    // 计算相关数据
    let accuracy = 0;
    let masteryLevel = 0;
    let nextReviewDateText = '';

    if (wordStats) {
      accuracy = wordStats.totalReviews > 0 ? 
        Math.round((wordStats.correctAnswers / wordStats.totalReviews) * 100) : 0;
      
      masteryLevel = sm2Algorithm.calculateMasteryLevel(wordStats);
      
      const nextDate = new Date(wordStats.nextReviewDate);
      nextReviewDateText = this.formatDate(nextDate);
    }

    // 检查是否收藏
    const favorites = wx.getStorageSync('favorites') || [];
    const isFavorite = favorites.includes(wordId);

    this.setData({
      wordInfo,
      wordStats,
      accuracy,
      masteryLevel,
      nextReviewDateText,
      isFavorite
    });
  },

  /**
   * 格式化日期
   */
  formatDate(date) {
    const now = new Date();
    const diffTime = date.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return '今天';
    } else if (diffDays === 1) {
      return '明天';
    } else if (diffDays === -1) {
      return '昨天';
    } else if (diffDays > 0) {
      return `${diffDays}天后`;
    } else {
      return `${Math.abs(diffDays)}天前`;
    }
  },

  /**
   * 播放单词音频
   */
  playAudio() {
    const { wordInfo } = this.data;
    
    if (wordInfo.audioUrl) {
      const innerAudioContext = wx.createInnerAudioContext();
      innerAudioContext.src = wordInfo.audioUrl;
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
   * 播放例句音频
   */
  playExampleAudio() {
    // 这里可以添加例句音频播放逻辑
    wx.showToast({
      title: '例句音频播放',
      icon: 'none'
    });
  },

  /**
   * 切换收藏状态
   */
  toggleFavorite() {
    const { wordInfo, isFavorite } = this.data;
    const favorites = wx.getStorageSync('favorites') || [];
    
    if (isFavorite) {
      // 取消收藏
      const index = favorites.indexOf(wordInfo.id);
      if (index > -1) {
        favorites.splice(index, 1);
      }
      wx.showToast({
        title: '已取消收藏',
        icon: 'none'
      });
    } else {
      // 添加收藏
      favorites.push(wordInfo.id);
      wx.showToast({
        title: '已添加收藏',
        icon: 'success'
      });
    }
    
    wx.setStorageSync('favorites', favorites);
    this.setData({ isFavorite: !isFavorite });
  },

  /**
   * 重置学习进度
   */
  resetProgress() {
    const { wordInfo } = this.data;
    
    wx.showModal({
      title: '确认重置',
      content: '确定要重置这个单词的学习进度吗？这个操作不可撤销。',
      success: (res) => {
        if (res.confirm) {
          // 移除单词统计信息
          const allWordStats = dataManager.getWordStats();
          const filteredStats = allWordStats.filter(stats => stats.wordId !== wordInfo.id);
          dataManager.saveWordStats(filteredStats);
          
          wx.showToast({
            title: '已重置进度',
            icon: 'success'
          });
          
          // 重新加载页面
          this.loadWordDetail(wordInfo.id);
        }
      }
    });
  },

  /**
   * 立即复习
   */
  reviewNow() {
    const { wordInfo } = this.data;
    
    // 跳转到学习页面，只学习这一个单词
    wx.navigateTo({
      url: `/pages/learning/index?mode=single&wordId=${wordInfo.id}`
    });
  },

  /**
   * 返回上一页
   */
  goBack() {
    wx.navigateBack();
  }
});
