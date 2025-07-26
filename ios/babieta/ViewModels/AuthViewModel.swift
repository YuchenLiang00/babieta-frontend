//
//  AuthViewModel.swift
//  babieta
//
//  Created by 梁育晨 on 2025/7/12.
//

import Combine
import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    @Published var fullName = ""

    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isLoginMode = true

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    var isLoggedIn: Bool {
        apiService.tokenManager.isLoggedIn
    }

    var currentUser: User? {
        apiService.tokenManager.currentUser
    }

    init() {
        // Listen to login state changes
        apiService.tokenManager.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func login() async {
        guard !email.isEmpty && !password.isEmpty else {
            showErrorMessage("请填写邮箱和密码")
            return
        }

        guard isValidEmail(email) else {
            showErrorMessage("请输入有效的邮箱地址")
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            _ = try await apiService.login(email: email, password: password)
            // Login successful, UI will update automatically via published properties
            clearForm()
        } catch {
            showErrorMessage(error.localizedDescription)
        }

        isLoading = false
    }

    func register() async {
        guard !email.isEmpty && !password.isEmpty else {
            showErrorMessage("请填写邮箱和密码")
            return
        }

        guard isValidEmail(email) else {
            showErrorMessage("请输入有效的邮箱地址")
            return
        }

        guard password == confirmPassword else {
            showErrorMessage("两次输入的密码不一致")
            return
        }

        guard password.count >= 6 else {
            showErrorMessage("密码长度至少为6位")
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            _ = try await apiService.register(
                email: email,
                password: password,
                username: username.isEmpty ? nil : username,
                fullName: fullName.isEmpty ? nil : fullName
            )

            // Auto login after successful registration
            await login()

        } catch {
            showErrorMessage(error.localizedDescription)
        }

        isLoading = false
    }

    func logout() {
        apiService.logout()
        clearForm()
    }

    func toggleMode() {
        isLoginMode.toggle()
        clearForm()
    }

    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        username = ""
        fullName = ""
        errorMessage = ""
        showError = false
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
