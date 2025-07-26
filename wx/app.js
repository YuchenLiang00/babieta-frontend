// app.js
App({
  globalData: {
    theme: { primary: '#4a86e8', card: 'rgba(255,255,255,0.92)', text: '#333' },
    fontSize: 18,
    userSettings: {}
  },

  onLaunch() {
    // 初始化用户设置
    const userSettings = wx.getStorageSync('userSettings') || {};
    this.globalData.userSettings = userSettings;

    // 初始化主题
    const theme = wx.getStorageSync('theme');
    if (theme) {
      this.globalData.theme = theme;
    }

    // 初始化字体大小
    const fontSize = wx.getStorageSync('fontSize');
    if (fontSize) {
      this.globalData.fontSize = fontSize;
    }

    // 展示欢迎消息
    wx.showToast({
      title: '欢迎使用俄语背单词',
      icon: 'none',
      duration: 2000
    });
  },

  // 更新全局主题
  updateTheme(theme) {
    this.globalData.theme = theme;
    wx.setStorageSync('theme', theme);
  },

  // 更新字体大小
  updateFontSize(size) {
    this.globalData.fontSize = size;
    wx.setStorageSync('fontSize', size);
  },

  // 更新用户设置
  updateUserSettings(settings) {
    this.globalData.userSettings = settings;
    wx.setStorageSync('userSettings', settings);
  }
});