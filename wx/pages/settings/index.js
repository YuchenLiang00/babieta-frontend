Page({
  data: {
    dailyGoal: 15, // 默认每日学习量
    bgStyle: 0, // 0:自然风景, 1:极简抽象, 2:城市建筑
    bgStyles: ['自然风景', '极简抽象', '城市建筑'],
    sunsetMode: false, // 日落模式默认关闭
    themeColor: 0, // 0:蓝色(默认), 1:绿色, 2:紫色
    themeColors: ['蓝色', '绿色', '紫色'],
    fontSize: 18 // 默认字体大小
  },

  onLoad() {
    // 读取本地存储的设置
    const savedSettings = wx.getStorageSync('userSettings');
    if (savedSettings) {
      this.setData({
        dailyGoal: savedSettings.dailyGoal || 15,
        bgStyle: savedSettings.bgStyle || 0,
        sunsetMode: savedSettings.sunsetMode || false,
        themeColor: savedSettings.themeColor || 0,
        fontSize: savedSettings.fontSize || 18
      });
    }
  },

  // 设置每日学习量
  setDailyGoal(e) {
    const value = e.detail.value;
    this.setData({ dailyGoal: value });
    this.saveSettings();
  },

  // 设置背景风格
  setBgStyle(e) {
    const value = e.detail.value;
    this.setData({ bgStyle: value });
    this.saveSettings();
    // 通知主页面更新背景
    wx.navigateBack();
  },

  // 切换日落模式
  toggleSunsetMode(e) {
    const value = e.detail.value;
    this.setData({ sunsetMode: value });
    this.saveSettings();
    // 通知主页面更新背景
    wx.navigateBack();
  },

  // 设置主题色
  setThemeColor(e) {
    const value = e.detail.value;
    this.setData({ themeColor: value });
    this.saveSettings();
    this.applyThemeColor(value);
  },

  // 设置字体大小
  setFontSize(e) {
    const value = e.detail.value;
    this.setData({ fontSize: value });
    this.saveSettings();
    wx.setStorageSync('fontSize', value);
  },

  // 保存设置到本地存储
  saveSettings() {
    const settings = {
      dailyGoal: this.data.dailyGoal,
      bgStyle: this.data.bgStyle,
      sunsetMode: this.data.sunsetMode,
      themeColor: this.data.themeColor,
      fontSize: this.data.fontSize
    };
    wx.setStorageSync('userSettings', settings);
  },

  // 应用主题色
  applyThemeColor(themeIndex) {
    const themes = [
      { primary: '#4a86e8', card: 'rgba(255,255,255,0.92)', text: '#333' }, // 蓝色
      { primary: '#4caf50', card: 'rgba(255,255,255,0.92)', text: '#333' }, // 绿色
      { primary: '#9c27b0', card: 'rgba(255,255,255,0.92)', text: '#333' }  // 紫色
    ];
    const theme = themes[themeIndex];
    wx.setStorageSync('theme', theme);
  }
});