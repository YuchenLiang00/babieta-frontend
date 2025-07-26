# Babieta - 俄语学习应用

一个基于iOS的俄语学习应用，支持单词记忆、复习和进度跟踪。

## 功能特点

- 🎯 智能单词学习系统
- 📊 学习进度统计
- 🔄 基于遗忘曲线的复习算法
- 🌙 深色模式支持
- ☁️ 云端数据同步（Supabase）
- 👤 用户认证系统

## Supabase 集成设置

### 1. 创建Supabase项目

1. 访问 [Supabase官网](https://supabase.com)
2. 创建新项目
3. 获取项目URL和匿名密钥

### 2. 数据库架构

在Supabase SQL编辑器中运行以下SQL语句创建必要的表：

```sql
-- 创建用户设置表
CREATE TABLE user_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_new_words_target INTEGER DEFAULT 20,
    background_image_index INTEGER DEFAULT 0,
    is_dark_mode BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 创建单词表
CREATE TABLE words (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    russian TEXT NOT NULL,
    chinese TEXT NOT NULL,
    pronunciation TEXT NOT NULL,
    examples TEXT[] DEFAULT '{}',
    part_of_speech TEXT DEFAULT 'сущ.',
    learning_level INTEGER DEFAULT 0,
    last_review_date TIMESTAMP WITH TIME ZONE,
    next_review_date TIMESTAMP WITH TIME ZONE,
    is_new BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建学习统计表
CREATE TABLE learning_stats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_words INTEGER DEFAULT 0,
    words_learned INTEGER DEFAULT 0,
    reviews_completed INTEGER DEFAULT 0,
    streak INTEGER DEFAULT 0,
    last_study_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 创建索引以优化查询性能
CREATE INDEX idx_words_user_id ON words(user_id);
CREATE INDEX idx_words_is_new ON words(is_new);
CREATE INDEX idx_words_next_review_date ON words(next_review_date);
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX idx_learning_stats_user_id ON learning_stats(user_id);

-- 启用行级安全策略
ALTER TABLE words ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_stats ENABLE ROW LEVEL SECURITY;

-- 创建安全策略
CREATE POLICY "Users can only access their own words" ON words
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own settings" ON user_settings
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own stats" ON learning_stats
    FOR ALL USING (auth.uid() = user_id);
```

### 3. 配置应用

1. 在 `SupabaseService.swift` 中更新您的Supabase配置：

```swift
private init() {
    let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
    let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
    
    supabase = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey
    )
}
```

2. 替换 `YOUR_SUPABASE_URL` 和 `YOUR_SUPABASE_ANON_KEY` 为您的实际配置。

### 4. 在Xcode中添加Supabase依赖

1. 在Xcode中打开项目
2. 选择 `File` → `Add Package Dependencies`
3. 输入URL: `https://github.com/supabase/supabase-swift`
4. 选择版本 2.5.1 或更高版本
5. 添加 `Supabase` 产品到您的目标

## 项目结构

```
babieta/
├── Models/
│   ├── Word.swift                 # 单词数据模型
│   ├── WordManager.swift          # 单词管理器
│   └── DatabaseModels.swift       # 数据库模型
├── Views/
│   ├── ContentView.swift          # 主界面
│   ├── AuthView.swift             # 认证界面
│   ├── LearningView.swift         # 学习界面
│   ├── SettingsView.swift         # 设置界面
│   └── ...
├── Services/
│   └── SupabaseService.swift      # Supabase服务
└── Utils/
    ├── AudioManager.swift         # 音频管理
    └── Extensions.swift           # 扩展
```

## 使用方法

1. 首次运行应用时，会显示认证界面
2. 注册或登录账号
3. 开始学习俄语单词
4. 数据会自动同步到云端

## 离线支持

应用支持离线使用，当网络不可用时：
- 使用本地存储的数据
- 网络恢复后自动同步到云端

## 开发环境要求

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## 许可证

MIT License
