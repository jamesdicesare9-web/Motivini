import Foundation

actor AuthService {
    static let shared = AuthService()
    private init() {}

    private let accountsFile = "accounts.json"

    // MARK: Register / Login

    func registerLocal(email: String, password: String, displayName: String) async throws -> Account {
        var accounts = await loadAccounts()
        guard !accounts.contains(where: { $0.email.caseInsensitiveCompare(email) == .orderedSame }) else {
            throw AuthError.emailInUse
        }

        let acc = Account(id: UUID(), email: email, displayName: displayName, authProvider: .local, families: [])
        accounts.append(acc)
        try await saveAccounts(accounts)

        guard KeychainService.set(password: Data(password.utf8), for: email) else {
            throw AuthError.keychain
        }
        return acc
    }

    func loginLocal(email: String, password: String) async throws -> Account {
        let accounts = await loadAccounts()
        guard let acc = accounts.first(where: { $0.email.caseInsensitiveCompare(email) == .orderedSame }) else {
            throw AuthError.notFound
        }
        guard let stored = KeychainService.getPassword(for: email),
              stored == Data(password.utf8) else {
            throw AuthError.badCredentials
        }
        return acc
    }

    func removeAccount(_ account: Account) async throws {
        var accounts = await loadAccounts()
        accounts.removeAll { $0.id == account.id }
        try await saveAccounts(accounts)
        KeychainService.delete(email: account.email)
    }

    /// Persist that an account belongs to a family.
    func attachFamily(_ family: Family, to account: Account) async throws -> Account {
        var accounts = await loadAccounts()
        guard let idx = accounts.firstIndex(where: { $0.id == account.id }) else {
            throw AuthError.notFound
        }
        var updated = accounts[idx]
        let summary = FamilySummary(id: family.id, name: family.name)
        if !updated.families.contains(summary) {
            updated.families.append(summary)
            accounts[idx] = updated
            try await saveAccounts(accounts)
        }
        return updated
    }

    /// Read-only for session restore.
    func allAccounts() async -> [Account] { await loadAccounts() }

    // MARK: Persistence helpers

    private func loadAccounts() async -> [Account] {
        await Persistence.shared.load([Account].self, from: accountsFile) ?? []
    }

    private func saveAccounts(_ accounts: [Account]) async throws {
        try await Persistence.shared.save(accounts, to: accountsFile)
    }
}

enum AuthError: Error, LocalizedError {
    case emailInUse, keychain, notFound, badCredentials
    var errorDescription: String? {
        switch self {
        case .emailInUse:     return "This email is already registered."
        case .keychain:       return "Could not securely save your password."
        case .notFound:       return "Account not found."
        case .badCredentials: return "Incorrect email or password."
        }
    }
}
