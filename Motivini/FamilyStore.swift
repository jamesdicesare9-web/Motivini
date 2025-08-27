import Foundation

actor FamilyStore {
    static let shared = FamilyStore()
    private init() {}

    private func filename(for id: UUID) -> String { "family_\(id.uuidString).json" }

    func loadFamily(id: UUID) async -> Family? {
        await Persistence.shared.load(Family.self, from: filename(for: id))
    }

    func saveFamily(_ family: Family) async throws {
        try await Persistence.shared.save(family, to: filename(for: family.id))
    }

    func createFamily(name: String, owner: Account) async -> Family {
        let adminMember = FamilyMember(id: UUID(), name: owner.displayName, avatar: "👤", role: .admin)
        let family = Family(
            id: UUID(), name: name,
            members: [adminMember],
            categories: [Category.sample],
            tasks: [],
            activityLog: [],
            pendingApprovals: [],
            childCredentials: [],
            memberPoints: [:],
            progress: [],
            pointsConfig: PointsConfig(pointsPerDollar: 10)
        )
        try? await saveFamily(family)
        return family
    }

    /// Enumerate all saved families on device (used for child login).
    func loadAllFamilies() async -> [Family] {
        do {
            let fm = FileManager.default
            let dir = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let urls = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasPrefix("family_") && $0.pathExtension == "json" }
            let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
            var out: [Family] = []
            for u in urls {
                if let fam = try? dec.decode(Family.self, from: Data(contentsOf: u)) { out.append(fam) }
            }
            return out
        } catch { return [] }
    }
}
