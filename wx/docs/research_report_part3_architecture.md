# iOS俄语背单词应用研究报告：第三部分 - 技术架构设计

## 1. 核心技术选型概览

为了构建一个现代化、易于维护且高性能的iOS应用，我们推荐采用以下核心技术栈：

- **UI框架**: **SwiftUI**
- **应用架构**: **MVVM (Model-View-ViewModel)**
- **数据持久化**: **SwiftData**
- **主力语言**: **Swift**

这个组合充分利用了Apple最新的技术生态，能够最大限度地提升开发效率和应用性能。

## 2. UI框架：SwiftUI vs. UIKit

对于一个2025年启动的新项目，选择SwiftUI是明确且正确的方向。

### 2.1 为什么选择SwiftUI？

- **声明式语法 (Declarative Syntax)**: SwiftUI的代码更简洁、更直观，开发者只需描述“UI应该是什么样”，而无需关心具体的绘制过程。这极大地减少了代码量，降低了出错的可能性。
- **与Swift语言无缝集成**: SwiftUI充分利用了Swift的现代特性，如`async/await`，使得处理异步操作和数据流变得异常简单。
- **实时预览 (Live Previews)**: 这是Xcode为SwiftUI提供的杀手级功能，开发者可以实时看到代码更改在UI上的反映，极大地加速了UI开发和调试的速度。
- **跨平台潜力**: 一套代码可以轻松地在iOS, iPadOS, macOS, watchOS上运行，为未来应用的扩展提供了无限可能。
- **面向未来的投资**: SwiftUI是Apple未来UI开发的方向，现在投入学习和使用，长远来看是回报最高的选择。

### 2.2 何时可能需要UIKit？

虽然我们将以SwiftUI为主，但在某些特定场景下，可能需要通过`UIViewRepresentable`或`UIViewControllerRepresentable`来桥接UIKit组件：

- **需要高度定制的复杂视图**: 如果遇到SwiftUI原生API无法实现的、非常规的UI控件或复杂的动画效果。
- **集成第三方SDK**: 很多成熟的第三方SDK仍然是基于UIKit开发的。

**结论**: **100% SwiftUI优先**。只在必要时才考虑桥接UIKit，以保证项目的现代性和简洁性。

## 3. 应用架构：MVVM

MVVM (Model-View-ViewModel) 架构与SwiftUI的响应式数据流天然契合，是目前SwiftUI应用最主流、最成熟的架构模式。

### 3.1 MVVM的核心组件

- **Model**: 数据模型。在我们的应用中，这就是由SwiftData定义的`Word`, `WordList`等数据对象。
- **View**: 视图。由SwiftUI代码定义的界面，负责展示数据和响应用户操作。View本身不包含任何业务逻辑。
- **ViewModel**: 视图模型。这是连接View和Model的桥梁。它从Model中获取数据，并将其处理成View可以直接展示的格式。同时，它也包含了View的所有业务逻辑和状态管理，例如处理用户的点击事件、调用算法更新单词状态等。

### 3.2 为什么MVVM适合我们的应用？

- **职责分离清晰**: View专注于展示，ViewModel专注于业务逻辑，Model专注于数据，分工明确，易于测试和维护。
- **与SwiftUI完美配合**: SwiftUI的`@State`, `@StateObject`, `@ObservedObject`等属性包装器就是为MVVM模式量身打造的，可以轻松实现View和ViewModel之间的数据绑定。
- **社区成熟，资源丰富**: 遇到问题时，可以轻松找到大量的教程和解决方案。

**替代方案TCA (The Composable Architecture)**: TCA是一个功能强大、一致性高的架构，但在状态管理上比MVVM更严格，学习曲线也更陡峭。对于我们的应用规模和复杂度，MVVM已经足够胜任，且团队上手更快。

## 4. 数据持久化：SwiftData

本地数据存储是背单词应用的核心。我们推荐使用Apple在WWDC23推出的**SwiftData**框架。

### 4.1 SwiftData的优势

- **专为Swift设计**: API完全使用现代Swift语法，非常简洁。只需在你的`class`前加上`@Model`宏，它就变成了一个可持久化的模型。
- **与SwiftUI深度集成**: 在SwiftUI视图中，使用`@Query`属性包装器就可以轻松地从数据库中获取数据并自动更新UI，无需编写任何额外的同步代码。
- **代码极简**: 相比于Core Data需要手动创建`.xcdatamodeld`文件和编写大量模板代码，SwiftData大大简化了配置过程。
- **强大的查询功能**: 支持谓词（Predicates）进行复杂的查询和过滤。

### 4.2 数据模型设计示例 (使用SwiftData)

```swift
import Foundation
import SwiftData

@Model
final class WordItem {
    @Attribute(.unique) var id: UUID
    var word: String
    var phoneticSymbol: String
    var definition: String
    var exampleSentences: [String]
    
    // SM-2 Algorithm Fields
    var nextReviewDate: Date
    var repetitionCount: Int
    var easinessFactor: Double
    var interval: Int
    
    @Relationship(inverse: \WordList.items) 
    var wordList: WordList?
    
    init(...) { ... }
}

@Model
final class WordList {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) 
    var items: [WordItem] = []
    
    init(...) { ... }
}
```

### 4.3 风险与备选方案

- **最低系统要求**: SwiftData要求**iOS 17**及以上版本。这可能是其唯一的、但也是最大的限制。如果产品要求支持更旧的iOS版本（如iOS 15或16），则SwiftData不可行。
- **备选方案**: 
    - **Core Data**: 如果需要支持旧系统，Core Data是Apple官方的传统方案，稳定可靠，但API较为陈旧和繁琐。
    - **GRDB.swift**: 这是一个基于SQLite的第三方开源库，以其高性能和强大的功能而闻名，被认为是Core Data的一个优秀替代品。它的学习曲线比Core Data平缓，且提供了更现代的Swift API。

**结论**: **首选SwiftData**，因为它代表了未来方向且开发体验最佳。在项目启动前，必须明确产品要求的最低支持系统版本。如果需要支持iOS 16或更早版本，**推荐使用GRDB.swift**作为替代方案。

## 5. 个性化设置与主题系统实现

- **数据存储**: 使用`@AppStorage`或`UserDefaults`来持久化存储用户的偏好设置，如每日学习量、主题选择、字体大小等。这些是轻量级的键值对存储，非常适合此场景。
- **主题系统**: 
    1.  定义一个`Theme`协议或结构体，包含颜色（如`primaryColor`, `backgroundColor`, `textColor`等）和字体信息。
    2.  创建多个具体的Theme实例（如`LightTheme`, `DarkTheme`, `PaperTheme`）。
    3.  使用`@State`或`@EnvironmentObject`在整个应用中传递和切换当前的主题。当用户更改设置时，更新这个状态变量，所有使用该主题的SwiftUI视图都会自动刷新，实现动态换肤。