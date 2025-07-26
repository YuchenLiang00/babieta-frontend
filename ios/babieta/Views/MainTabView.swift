//
//  MainTabView.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var wordManager: WordManager

    var body: some View {
        TabView {
            // 主页标签 - 使用杠铃图标表示练习
            HomeView(wordManager: wordManager)
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                }

            // 数据统计标签 - 只保留图标
            DataStatsView(wordManager: wordManager)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                }

            // 个人中心标签 - 只保留图标
            ProfileView(wordManager: wordManager)
                .tabItem {
                    Image(systemName: "person.fill")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView(wordManager: WordManager())
}
