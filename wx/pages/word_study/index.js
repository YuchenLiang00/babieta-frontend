const dataManager = require('../../utils/dataManager');
const { getTodayBgUrl } = require('../../utils/bg');

Page({
  data: {
    // 游客模式标识
    isGuestMode: false,
    
    // 显示的单词信息
    displayWord: {
      word: 'Привет',
      translation: '你好',
      pronunciation: 'privet'
    },
    
    // 统计信息
    reviewCount: 0,
    newWordsCount: 0,
    
    // 背景图片
    backgroundImage: '',
    
    // 用户设置
    userSettings: {},
    theme: {},
    fontSize: 18
  },

  onLoad() {
    console.log('=== 主页面加载开始 ===');
    
    // 检测运行环境
    try {
      const accountInfo = wx.getAccountInfoSync();
      console.log('账户信息:', accountInfo);
      
      // 检测是否为游客模式
      if (accountInfo.miniProgram && accountInfo.miniProgram.appId === 'touristappid') {
        console.log('检测到游客模式，将使用兼容性配置');
        this.setData({ isGuestMode: true });
      }
    } catch (error) {
      console.log('无法获取账户信息（可能是游客模式）:', error);
      this.setData({ isGuestMode: true });
    }
    
    // 加载用户设置
    this.loadUserSettings();
    
    // 设置背景
    this.setBg();
    
    // 加载统计数据
    this.loadStatistics();
    
    // 加载随机展示单词
    this.loadDisplayWord();
  },

  onShow() {
    // 每次显示时刷新统计数据
    this.loadStatistics();
  },

  /**
   * 加载用户设置
   */
  loadUserSettings() {
    const userSettings = dataManager.getUserSettings();
    const theme = wx.getStorageSync('theme') || this.data.theme;
    const fontSize = wx.getStorageSync('fontSize') || 18;
    
    this.setData({ 
      userSettings, 
      theme, 
      fontSize 
    });
  },

  /**
   * 设置背景
   */
  setBg() {
    const { bgStyle = 0, sunsetMode = false } = this.data.userSettings;
    this.setData({
      backgroundImage: getTodayBgUrl(bgStyle, sunsetMode)
    });
  },

  /**
   * 加载统计数据
   */
  loadStatistics() {
    const todayPlan = dataManager.getTodayPlan();
    
    console.log('今日学习计划:', todayPlan);
    
    // 确保至少有一些数据可以测试
    const reviewCount = todayPlan.reviewWords || 0;
    const newWordsCount = todayPlan.newWords || 5; // 至少显示5个新单词用于测试
    
    this.setData({
      reviewCount,
      newWordsCount
    });
  },

  /**
   * 加载随机展示单词
   */
  loadDisplayWord() {
    const allWords = dataManager.getAllWords();
    if (allWords.length > 0) {
      const randomIndex = Math.floor(Math.random() * allWords.length);
      const randomWord = allWords[randomIndex];
      
      this.setData({
        displayWord: {
          word: randomWord.word,
          translation: randomWord.translation,
          pronunciation: randomWord.pronunciation
        }
      });
    }
  },

  /**
   * 开始复习
   */
  startReview(e) {
    console.log('复习按钮被点击了！', e);
    
    // 直接跳转，不使用可能在游客模式下有问题的API
    wx.navigateTo({
      url: '/pages/learning/index?mode=review',
      success: () => {
        console.log('导航到复习页面成功');
      },
      fail: (err) => {
        console.error('导航到复习页面失败:', err);
        // 使用console.log而不是wx.showToast，避免游客模式限制
        console.log('页面跳转失败，错误信息:', JSON.stringify(err));
      }
    });
  },

  /**
   * 开始学习新词
   */
  startLearning(e) {
    console.log('=== 学习按钮被点击 ===', e);
    console.log('游客模式状态:', this.data.isGuestMode);
    
    // 在游客模式下给用户提示
    if (this.data.isGuestMode) {
      console.log('游客模式下尝试页面跳转...');
    }
    
    console.log('准备跳转到学习页面...');
    
    const navigateUrl = '/pages/learning/index?mode=learn';
    console.log('跳转URL:', navigateUrl);
    
    wx.navigateTo({
      url: navigateUrl,
      success: (res) => {
        console.log('导航到学习页面成功:', res);
      },
      fail: (err) => {
        console.error('navigateTo 失败:', err);
        console.log('错误详情:', JSON.stringify(err));
        
        // 游客模式下尝试其他方式
        console.log('尝试不带参数的跳转...');
        wx.navigateTo({
          url: '/pages/learning/index',
          success: (res) => {
            console.log('使用简单URL跳转成功:', res);
          },
          fail: (err2) => {
            console.error('所有跳转方式都失败:', err2);
            console.log('跳转失败详情:', JSON.stringify(err2));
            
            // 最后的降级方案：提示用户
            if (this.data.isGuestMode) {
              console.log('游客模式下页面跳转受限，建议使用真机或开发者工具测试');
            }
          }
        });
      }
    });
  },

  /**
   * 打开设置页面
   */
  openSettings() {
    wx.navigateTo({
      url: '/pages/settings/index'
    });
  }
});
