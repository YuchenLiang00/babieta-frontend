//
//  LaunchScreenView.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/1.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.5
    @StateObject private var audioManager = AudioManager()

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // 应用图标或Logo
                VStack(spacing: 15) {
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    Text("Babieta")
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(logoOpacity)

                    Text("小语种背单词")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .opacity(logoOpacity)
                }
            }
        }
        .onAppear {
            // 播放启动音效
            audioManager.playSuccess()

            withAnimation(.easeInOut(duration: 1.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
