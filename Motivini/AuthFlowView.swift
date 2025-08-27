import SwiftUI

struct AuthFlowView: View {
    enum Mode: String, CaseIterable, Identifiable { case parent = "Parent", child = "Child"; var id: String { rawValue } }
    @State private var mode: Mode = .parent

    var body: some View {
        VStack(spacing: 16) {
            Text("Motivini").font(.largeTitle).bold()
            Picker("Mode", selection: $mode) { ForEach(Mode.allCases) { Text($0.rawValue).tag($0) } }
                .pickerStyle(.segmented)
            if mode == .parent { ParentAuthForm() } else { ChildAuthForm() }
        }
        .padding()
    }
}

// MARK: Parent
struct ParentAuthForm: View {
    @State private var showLogin = true
    var body: some View {
        VStack(spacing: 16) {
            if showLogin { LoginView() } else { RegisterView() }
            Button(showLogin ? "Create an account" : "I already have an account") { withAnimation { showLogin.toggle() } }
                .font(.footnote)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .textContentType(.username).textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding().background(.thinMaterial).cornerRadius(12)
            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding().background(.thinMaterial).cornerRadius(12)
            if let error { Text(error).foregroundColor(.red).font(.footnote) }
            Button("Sign In") { Task { await signIn() } }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty)
            Divider().padding(.vertical, 8)
            AppleSignInButton()
            GoogleSignInButton()
        }
    }
    private func signIn() async {
        do { try await app.login(email: email, password: password) }
        catch { self.error = error.localizedDescription }
    }
}

struct RegisterView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var familyName = "My Family"
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            TextField("Your Name", text: $displayName).padding().background(.thinMaterial).cornerRadius(12)
            TextField("Email", text: $email)
                .textContentType(.username).textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding().background(.thinMaterial).cornerRadius(12)
            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .padding().background(.thinMaterial).cornerRadius(12)
            TextField("Family Name", text: $familyName).padding().background(.thinMaterial).cornerRadius(12)
            if let error { Text(error).foregroundColor(.red).font(.footnote) }
            Button("Create Account") { Task { await create() } }
                .buttonStyle(.borderedProminent)
                .disabled(displayName.isEmpty || email.isEmpty || password.isEmpty)
        }
    }
    private func create() async {
        do { try await app.register(displayName: displayName, email: email, password: password, familyName: familyName) }
        catch { self.error = error.localizedDescription }
    }
}

// MARK: Child
struct ChildAuthForm: View {
    @EnvironmentObject var app: AppViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            TextField("Username", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding().background(.thinMaterial).cornerRadius(12)
            SecureField("Password", text: $password)
                .padding().background(.thinMaterial).cornerRadius(12)
            if let error { Text(error).foregroundColor(.red).font(.footnote) }
            Button("Sign In as Child") { Task { await signInChild() } }
                .buttonStyle(.borderedProminent)
                .disabled(username.isEmpty || password.isEmpty)
            Text("Child logins work on the same device that the parent used to create the family.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }

    private func signInChild() async {
        if let result = await ChildAuthService.shared.loginChild(username: username, password: password) {
            let acc = Account(id: UUID(), email: "", displayName: result.member.name,
                              authProvider: .local,
                              families: [FamilySummary(id: result.family.id, name: result.family.name)])
            await MainActor.run {
                app.currentAccount = acc
                app.selectedFamily = result.family
                app.isLoading = false
            }
        } else {
            await MainActor.run { self.error = "Invalid child credentials." }
        }
    }
}

// MARK: Logo buttons
struct AppleSignInButton: View {
    var body: some View {
        Button {} label: {
            HStack { Image(systemName: "applelogo"); Text("Sign in with Apple") }
                .frame(maxWidth: .infinity)
        }.buttonStyle(.bordered)
    }
}

struct GoogleSignInButton: View {
    var body: some View {
        Button {} label: {
            HStack {
                if let ui = UIImage(named: "google") {
                    Image(uiImage: ui).resizable().frame(width: 18, height: 18).clipShape(Circle())
                } else {
                    Text("G").font(.headline).frame(width: 18, height: 18).overlay(Circle().strokeBorder(.primary.opacity(0.3)))
                }
                Text("Sign in with Google")
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.bordered)
    }
}
