//
//  babietaApp.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI

@main
struct babietaApp: App {
    @StateObject private var wordManager = WordManager()
    @State private var isAuthenticated = false
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunchScreen {
                    LaunchScreenView()
                        .onAppear {
                            // 检查用户认证状态
                            checkAuthenticationState()

                            // 2秒后隐藏启动屏幕
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showLaunchScreen = false
                            }
                        }
                } else {
                    if isAuthenticated {
                        MainTabView(wordManager: wordManager)
                    } else {
                        AuthView(isAuthenticated: $isAuthenticated)
                            .onReceive(APIService.shared.tokenManager.$isLoggedIn) { isLoggedIn in
                                isAuthenticated = isLoggedIn
                            }
                    }
                }
            }
            .onChange(of: isAuthenticated) { authenticated in
                if authenticated {
                    wordManager.handleUserSignIn()
                } else {
                    wordManager.handleUserSignOut()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
                isAuthenticated = false
            }
            .alert("错误", isPresented: $wordManager.showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(wordManager.errorMessage)
            }
        }
    }

    private func checkAuthenticationState() {
        // 检查是否有保存的 token
        let tokenManager = APIService.shared.tokenManager
        isAuthenticated = tokenManager.isLoggedIn
    }
}
