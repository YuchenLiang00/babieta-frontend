# Babieta Frontend - API 集成指南

## 🎯 项目概述
Babieta（巴别塔）是一个智能化的俄语学习应用。后端提供完整的RESTful API，前端负责用户界面和交互体验。

## 🔗 后端API概览

### 基础信息
- **公网地址**: 47.113.120.111
- **API 尾缀**: `/api/v1`
- **认证方式**: JWT Bearer Token
- **响应格式**: JSON
- **错误处理**: 标准HTTP状态码

### 🔐 认证流程
```javascript
// 1. 用户登录
POST /api/v1/auth/login
Content-Type: application/x-www-form-urlencoded
Body: username=user&password=pass

Response: {
  "access_token": "eyJ...",
  "token_type": "bearer"
}

// 2. 使用Token访问保护的端点
GET /api/v1/users/me
Authorization: Bearer eyJ...
```

## 🎨 推荐前端技术栈

### 方案1：React + TypeScript + Vite（推荐）
```bash
npm create vite@latest babieta-frontend -- --template react-ts
cd babieta-frontend
npm install axios @tanstack/react-query lucide-react
npm install -D tailwindcss postcss autoprefixer
```

### 方案2：Next.js 14 + TypeScript
```bash
npx create-next-app@latest babieta-frontend --typescript --tailwind --eslint --app
cd babieta-frontend
npm install axios swr
```

### 方案3：Vue 3 + TypeScript + Vite
```bash
npm create vue@latest babieta-frontend
# 选择 TypeScript, Router, Pinia
cd babieta-frontend
npm install axios pinia
```

## 🛠️ 核心功能模块

### 1. 认证模块
```typescript
// types/auth.ts
export interface LoginRequest {
  username: string;
  password: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
}

export interface User {
  id: number;
  username: string;
  email: string;
  full_name: string;
  is_active: boolean;
}
```

### 2. 学习系统模块（核心）
```typescript
// types/learning.ts
export interface LearningWord {
  word_id: number;
  russian_word: string;
  pronunciation?: string;
  meanings: WordMeaning[];
  learning_mode: 'recognition' | 'recall' | 'listening';
  difficulty_level: number;
  review_type: 'new' | 'review' | 'forgotten';
}

export interface LearningSession {
  words: LearningWord[];
  session_id: string;
  total_pending: number;
  estimated_time: number;
}

export interface WordResult {
  word_id: number;
  is_correct: boolean;
  response_time_ms: number;
  learning_mode: string;
  attempt_count: number;
}
```

### 3. API 服务封装
```typescript
// services/api.ts
import axios from 'axios';

const API_BASE = 'http://localhost:8000/api/v1';

const api = axios.create({
  baseURL: API_BASE,
});

// 请求拦截器 - 添加认证头
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 响应拦截器 - 处理错误
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

## 🎯 关键API端点集成

### 1. 智能学习系统（最重要）
```typescript
// services/learning.ts
export const learningService = {
  // 获取下一批学习词汇
  async getNextWords(params: {
    mode?: 'new' | 'review' | 'mixed';
    count?: number;
    difficulty_level?: number;
  }): Promise<LearningSession> {
    const response = await api.get('/learning/next-words', { params });
    return response.data;
  },

  // 提交学习结果
  async submitSession(sessionId: string, results: WordResult[]): Promise<any> {
    const response = await api.post(`/learning/sessions/${sessionId}/submit`, {
      word_results: results
    });
    return response.data;
  },

  // 获取学习进度
  async getProgress(period = 'today'): Promise<any> {
    const response = await api.get('/learning/progress', {
      params: { period }
    });
    return response.data;
  }
};
```

### 2. 用户管理
```typescript
// services/user.ts
export const userService = {
  async getCurrentUser(): Promise<User> {
    const response = await api.get('/users/me');
    return response.data;
  },

  async updateProfile(data: Partial<User>): Promise<User> {
    const response = await api.put('/users/me', data);
    return response.data;
  },

  async getUserStats(): Promise<any> {
    const response = await api.get('/users/me/stats');
    return response.data;
  }
};
```

### 3. 词书管理
```typescript
// services/wordbooks.ts
export const wordbookService = {
  async getWordbooks(params?: {
    difficulty_level?: number;
    category?: string;
    limit?: number;
    offset?: number;
  }): Promise<any> {
    const response = await api.get('/wordbooks', { params });
    return response.data;
  },

  async subscribeWordbook(wordbookId: string): Promise<any> {
    const response = await api.post(`/wordbooks/${wordbookId}/subscribe`);
    return response.data;
  }
};
```

## 🎨 UI/UX 设计建议

### 核心页面结构
```
/                    # 首页/仪表板
/login              # 登录页面
/register           # 注册页面
/learn              # 学习界面（核心）
/review             # 复习界面
/progress           # 进度统计
/wordbooks          # 词书管理
/profile            # 个人资料
/settings           # 设置页面
```

### 学习界面设计要点
1. **卡片式学习**: 一次显示一个单词
2. **模式切换**: 识别/回忆/听力三种模式
3. **进度指示**: 当前会话进度条
4. **即时反馈**: 正确/错误的视觉反馈
5. **统计显示**: 实时准确率和学习时间

### 组件设计建议
```typescript
// components/learning/
├── LearningCard.tsx          # 学习卡片
├── ProgressBar.tsx          # 进度条
├── ModeSelector.tsx         # 学习模式选择
├── ResultFeedback.tsx       # 结果反馈
└── SessionSummary.tsx       # 会话总结

// components/dashboard/
├── StatisticsOverview.tsx   # 统计概览
├── LearningStreak.tsx       # 学习连击
├── WeakAreasChart.tsx       # 薄弱点图表
└── RecommendationsList.tsx  # 推荐列表
```

## 🚀 开发启动步骤

### 1. 初始化前端项目
```bash
# 创建项目
npm create vite@latest babieta-frontend -- --template react-ts
cd babieta-frontend

# 安装依赖
npm install axios @tanstack/react-query lucide-react clsx
npm install -D tailwindcss postcss autoprefixer @types/node

# 配置Tailwind CSS
npx tailwindcss init -p
```

### 2. 项目结构建议
```
src/
├── components/          # 可复用组件
├── pages/              # 页面组件
├── services/           # API服务
├── types/              # TypeScript类型定义
├── hooks/              # 自定义React Hooks
├── utils/              # 工具函数
├── contexts/           # React Contexts
└── assets/             # 静态资源
```

### 3. 环境配置
```typescript
// .env.local
VITE_API_BASE_URL=http://localhost:8000/api/v1
VITE_APP_NAME=Babieta
```

## 📱 移动端适配建议

### 响应式设计要点
- 使用Tailwind CSS的响应式类
- 优先考虑移动端体验
- 触摸友好的按钮和交互
- 适配不同屏幕尺寸

### PWA支持
```bash
npm install vite-plugin-pwa workbox-window
```

## 🧪 测试策略

### 推荐测试工具
```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

### 测试重点
1. API集成测试
2. 学习流程端到端测试
3. 用户认证流程测试
4. 响应式布局测试

## 📚 学习资源

### React + TypeScript
- [React TypeScript Cheatsheet](https://react-typescript-cheatsheet.netlify.app/)
- [TanStack Query 文档](https://tanstack.com/query/latest)

### API集成最佳实践
- 使用React Query进行数据获取和缓存
- 实现乐观更新提升用户体验
- 错误边界处理API错误
- 加载状态管理

---

## 📞 开发协调

**前端仓库建议**: `babieta-frontend`  
**开发模式**: 前后端分离开发  
**API文档**: 参考后端的 `API_DESIGN_SPECIFICATION.md`  
**协调方式**: 通过API契约进行前后端对接  

**下一步**: 选择前端技术栈并初始化项目，然后开始实现认证和学习核心功能。
