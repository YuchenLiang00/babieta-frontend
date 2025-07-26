// 背景图管理工具
// 不同风格的背景图列表
const bgStyles = {
  nature: [
    '/assets/bg/nature/1.jpg',
    '/assets/bg/nature/2.jpg',
    '/assets/bg/nature/3.jpg',
    '/assets/bg/nature/4.jpg',
    '/assets/bg/nature/5.jpg',
  ],
  minimal: [
    '/assets/bg/minimal/1.jpg',
    '/assets/bg/minimal/2.jpg',
    '/assets/bg/minimal/3.jpg',
    '/assets/bg/minimal/4.jpg',
    '/assets/bg/minimal/5.jpg',
  ],
  urban: [
    '/assets/bg/urban/1.jpg',
    '/assets/bg/urban/2.jpg',
    '/assets/bg/urban/3.jpg',
    '/assets/bg/urban/4.jpg',
    '/assets/bg/urban/5.jpg',
  ],
  sunset: [
    '/assets/bg/sunset/1.jpg',
    '/assets/bg/sunset/2.jpg',
    '/assets/bg/sunset/3.jpg',
  ]
};

// 判断是否为日落时间 (简单模拟: 18:00-6:00)
function isSunsetTime() {
  const hour = new Date().getHours();
  return hour >= 18 || hour < 6;
}

// 获取今日背景图URL
function getTodayBgUrl(style = 0, sunsetMode = false) {
  // 根据设置选择背景风格
  const styleKeys = ['nature', 'minimal', 'urban'];
  const selectedStyle = styleKeys[style] || 'nature';
  const bgList = bgStyles[selectedStyle];
  
  // 如果启用日落模式且当前是日落时间，使用日落背景
  if (sunsetMode && isSunsetTime()) {
    const sunsetList = bgStyles.sunset;
    const day = new Date().getDate();
    return sunsetList[day % sunsetList.length];
  }
  
  // 否则使用所选风格的背景
  const day = new Date().getDate();
  return bgList[day % bgList.length];
}

module.exports = {
  getTodayBgUrl,
  bgStyles,
  isSunsetTime
};
