import Foundation

final class SessionStore {
    static let shared = SessionStore()
    private init() {}

    private let kAccountId = "motv.currentAccountId"
    private let kFamilyId  = "motv.currentFamilyId"

    var lastAccountId: UUID? {
        (UserDefaults.standard.string(forKey: kAccountId)).flatMap(UUID.init)
    }
    var lastFamilyId: UUID? {
        (UserDefaults.standard.string(forKey: kFamilyId)).flatMap(UUID.init)
    }

    func saveSession(accountId: UUID, familyId: UUID?) {
        UserDefaults.standard.set(accountId.uuidString, forKey: kAccountId)
        if let fid = familyId { UserDefaults.standard.set(fid.uuidString, forKey: kFamilyId) }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: kAccountId)
        UserDefaults.standard.removeObject(forKey: kFamilyId)
    }
}
