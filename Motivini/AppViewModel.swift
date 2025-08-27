import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var currentAccount: Account? = nil
    @Published var selectedFamily: Family? = nil

    init() { Task { await restoreSession() } }

    // MARK: Parent auth

    func register(displayName: String, email: String, password: String, familyName: String) async throws {
        isLoading = true; defer { isLoading = false }

        let acc = try await AuthService.shared.registerLocal(email: email, password: password, displayName: displayName)
        let fam = await FamilyStore.shared.createFamily(name: familyName, owner: acc)
        let updated = try await AuthService.shared.attachFamily(fam, to: acc)

        currentAccount = updated
        selectedFamily  = fam
        SessionStore.shared.saveSession(accountId: updated.id, familyId: fam.id)
    }

    func login(email: String, password: String) async throws {
        isLoading = true; defer { isLoading = false }

        let acc = try await AuthService.shared.loginLocal(email: email, password: password)
        currentAccount = acc

        if let savedFamilyId = SessionStore.shared.lastFamilyId,
           let fam = await FamilyStore.shared.loadFamily(id: savedFamilyId) {
            selectedFamily = fam
        } else if let first = acc.families.first,
                  let fam = await FamilyStore.shared.loadFamily(id: first.id) {
            selectedFamily = fam
            SessionStore.shared.saveSession(accountId: acc.id, familyId: fam.id)
        } else {
            selectedFamily = nil
        }
    }

    func switchFamily(to summary: FamilySummary) async {
        guard let fam = await FamilyStore.shared.loadFamily(id: summary.id) else { return }
        selectedFamily = fam
        if let acc = currentAccount { SessionStore.shared.saveSession(accountId: acc.id, familyId: fam.id) }
    }

    func saveFamily(_ family: Family) async {
        try? await FamilyStore.shared.saveFamily(family)
        selectedFamily = family
        if let acc = currentAccount { SessionStore.shared.saveSession(accountId: acc.id, familyId: family.id) }
    }

    func signOut() {
        currentAccount = nil
        selectedFamily  = nil
        SessionStore.shared.clear()
    }

    // MARK: Session restore

    private func restoreSession() async {
        guard let accId = SessionStore.shared.lastAccountId else { return }
        let accounts = await AuthService.shared.allAccounts()
        guard let acc = accounts.first(where: { $0.id == accId }) else { return }
        self.currentAccount = acc

        if let fid = SessionStore.shared.lastFamilyId,
           let fam = await FamilyStore.shared.loadFamily(id: fid) {
            self.selectedFamily = fam
        }
    }
}
