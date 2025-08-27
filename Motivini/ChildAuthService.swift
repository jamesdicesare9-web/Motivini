import Foundation

struct ChildLoginResult {
    let family: Family
    let member: FamilyMember
}

actor ChildAuthService {
    static let shared = ChildAuthService()
    private init() {}

    func upsertCredential(for family: inout Family,
                          memberId: UUID,
                          username: String,
                          email: String?,
                          password: String) async {
        let hash = PasswordHasher.hash(password)
        if let i = family.childCredentials.firstIndex(where: { $0.memberId == memberId }) {
            family.childCredentials[i].username = username
            family.childCredentials[i].email = email
            family.childCredentials[i].passwordHash = hash
        } else {
            family.childCredentials.append(
                ChildCredential(id: UUID(), memberId: memberId, username: username, email: email, passwordHash: hash)
            )
        }
        try? await FamilyStore.shared.saveFamily(family)
    }

    func loginChild(username: String, password: String) async -> ChildLoginResult? {
        let families = await FamilyStore.shared.loadAllFamilies()
        let hash = PasswordHasher.hash(password)

        for fam in families {
            if let cred = fam.childCredentials.first(where: { $0.username.caseInsensitiveCompare(username) == .orderedSame }),
               cred.passwordHash == hash,
               let member = fam.members.first(where: { $0.id == cred.memberId }) {
                return ChildLoginResult(family: fam, member: member)
            }
        }
        return nil
    }
}
