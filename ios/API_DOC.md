# 俄语单词学习 API 文档

## 基础信息
- **API 地址**: http://47.113.120.111:8000
- **文档页面**: http://47.113.120.111:8000/docs
- **数据量**: 8,591 个俄语单词，8,346 个已翻译

## 🔐 用户认证 API

### 注册用户
```http
POST /api/v1/auth/register
Content-Type: application/json

{
    "username": "your_username",
    "email": "your_email@example.com", 
    "password": "your_password",
    "full_name": "Your Full Name" // 可选
}
```

### 用户登录
```http
POST /api/v1/auth/login
Content-Type: application/x-www-form-urlencoded

username=your_username&password=your_password
```

**返回:**
```json
{
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer"
}
```

## 📚 词汇 API

> 所有词汇 API 都需要在 Header 中包含: `Authorization: Bearer <access_token>`

### 获取随机单词（用于学习）
```http
GET /api/v1/vocabulary/random?limit=10&difficulty_levels=1,2
```

**参数:**
- `limit`: 返回单词数量 (默认: 10)
- `difficulty_levels`: 难度等级数组 (1-5, 可选)

### 搜索单词
```http
GET /api/v1/vocabulary/?search=дом&limit=20
```

### 按难度获取单词
```http
GET /api/v1/vocabulary/?difficulty=1&limit=50
```

### 按分类获取单词
```http
GET /api/v1/vocabulary/?category=noun&limit=30
```

### 获取单词详情
```http
GET /api/v1/vocabulary/123
```

### 获取所有分类
```http
GET /api/v1/vocabulary/categories
```

**返回示例:**
```json
[
    {
        "id": 1,
        "russian_word": "дом",
        "english_translation": "house, home",
        "chinese_translation": "房子，家",
        "pronunciation": "до́м",
        "difficulty_level": 1,
        "category": "noun",
        "meanings": [
            {
                "id": 1,
                "translation": "house",
                "definition": "A building for human habitation",
                "example_ru": "Я иду домой",
                "example_tl": "I'm going home"
            }
        ]
    }
]
```

## 📊 学习记录 API

### 获取学习进度
```http
GET /api/v1/learning/progress
```

**返回:**
```json
{
    "new": 150,
    "learning": 45,
    "mastered": 23,
    "forgotten": 5,
    "total": 223
}
```

### 提交学习会话
```http
POST /api/v1/learning/study-session
Content-Type: application/json

{
    "vocabulary_id": 123,
    "is_correct": true,
    "learning_mode": "recognition" // "recognition", "recall", "listening"
}
```

### 获取学习记录
```http
GET /api/v1/learning/records?status=learning&limit=50
```

## 👤 用户管理 API

### 获取当前用户信息
```http
GET /api/v1/users/me
```

### 更新用户信息
```http
PUT /api/v1/users/me
Content-Type: application/json

{
    "full_name": "New Name",
    "email": "new_email@example.com"
}
```

## 📱 iOS 应用集成示例

### Swift 配置
```swift
struct APIConfig {
    static let baseURL = "http://47.113.120.111:8000"
    static let apiVersion = "/api/v1"
    
    static var headers: [String: String] {
        var headers = ["Content-Type": "application/json"]
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
}

// 使用示例
let url = "\(APIConfig.baseURL)\(APIConfig.apiVersion)/vocabulary/random?limit=10"
```

### 网络请求示例
```swift
func fetchRandomWords(limit: Int = 10) async throws -> [Vocabulary] {
    let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.apiVersion)/vocabulary/random?limit=\(limit)")!
    var request = URLRequest(url: url)
    APIConfig.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([Vocabulary].self, from: data)
}
```

## 🎯 学习功能建议

1. **单词卡片**: 使用 `/vocabulary/random` 获取学习单词
2. **搜索功能**: 使用 `/vocabulary/?search=` 实现搜索
3. **难度分级**: 利用 `difficulty_level` 字段进行分级学习
4. **进度跟踪**: 使用 `/learning/progress` 显示学习统计
5. **学习记录**: 每次学习后调用 `/learning/study-session`

## 🗂️ 数据结构说明

- **难度等级**: 1(最简单) - 5(最难)
- **学习状态**: new, learning, mastered, forgotten
- **学习模式**: recognition(识别), recall(回忆), listening(听力)
- **分类**: noun, verb, adjective, adverb 等

---

🎉 你的俄语单词学习后端 API 已经完全部署并可用！
