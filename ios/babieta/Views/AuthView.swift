//
//  AuthView.swift
//  babieta
//
//  Updated by 梁育晨 on 2025/7/12.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Binding var isAuthenticated: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Logo/Title
                VStack(spacing: 10) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Russian Vocabulary")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 50)

                Spacer()

                // Auth Form
                VStack(spacing: 15) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)

                    if !viewModel.isLoginMode {
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Auth Button
                    Button(action: {
                        Task {
                            await authenticateUser()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isLoginMode ? "Sign In" : "Sign Up")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)

                    // Toggle Auth Mode
                    Button(action: {
                        viewModel.toggleMode()
                    }) {
                        Text(
                            viewModel.isLoginMode
                                ? "Don't have an account? Sign Up"
                                : "Already have an account? Sign In"
                        )
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Temporary Skip Button
                Button(action: {
                    // TODO: Remove this when backend is ready
                    isAuthenticated = true
                }) {
                    Text("Skip Login (Development)")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Welcome")
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                self.isAuthenticated = true
            }
        }
    }

    private func authenticateUser() async {
        if viewModel.isLoginMode {
            await viewModel.login()
        } else {
            await viewModel.register()
        }
    }
}

#Preview {
    AuthView(isAuthenticated: .constant(false))
}
