import Foundation

// MARK: - Core Types

enum Role: String, Codable, CaseIterable, Identifiable {
    case admin, parent, child
    var id: String { rawValue }
}

enum AuthProvider: String, Codable { case local, apple, google }

struct FamilySummary: Codable, Hashable {
    var id: UUID
    var name: String
}

struct Account: Identifiable, Codable, Hashable {
    var id: UUID
    var email: String
    var displayName: String
    var authProvider: AuthProvider
    var families: [FamilySummary]
}

struct PointsConfig: Codable, Hashable {
    /// Example: pointsPerDollar = 10  ⇒ $1 per 10 pts
    var pointsPerDollar: Double
    func dollars(forPoints pts: Int) -> Double {
        guard pointsPerDollar > 0 else { return 0 }
        return Double(pts) / pointsPerDollar
    }
}

struct Family: Identifiable, Codable {
    var id: UUID
    var name: String
    var members: [FamilyMember]
    var categories: [Category]
    var tasks: [MVTask]
    var activityLog: [ActivityLogEntry]
    var pendingApprovals: [Approval]
    var childCredentials: [ChildCredential]   // parent-managed child logins
    var memberPoints: [UUID: Int]             // memberId → total points
    var progress: [ProgressCounter]           // progress toward category targets
    var pointsConfig: PointsConfig
}

struct FamilyMember: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var avatar: String
    var role: Role
}

struct Category: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var emoji: String?        // one emoji; optional
    var colorHex: String
    var isDefault: Bool
    var pointValue: Int       // points when target met
    var targetCount: Int      // how many logs before points awarded
}

/// Renamed from `Task` to avoid conflict with Swift Concurrency `Task`.
struct MVTask: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var categoryId: UUID
    var assigneeId: UUID?
    var dueDate: Date?
    var isCompleted: Bool
    var completedById: UUID?
    var completedAt: Date?
}

struct ActivityLogEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var memberId: UUID?
    var description: String
    var categoryId: UUID?
}

struct ProgressCounter: Identifiable, Codable, Hashable {
    var id: UUID
    var memberId: UUID
    var categoryId: UUID
    var count: Int
}

/// UPDATED: persist a password hash so child logins survive relaunch.
struct ChildCredential: Identifiable, Codable, Hashable {
    var id: UUID
    var memberId: UUID
    var username: String
    var email: String?
    var passwordHash: String?
}

enum ApprovalKind: String, Codable { case task, activity }

struct Approval: Identifiable, Codable, Hashable {
    var id: UUID
    var kind: ApprovalKind
    var taskId: UUID?          // for .task
    var memberId: UUID?        // for .activity
    var categoryId: UUID?      // for .activity
    var submittedById: UUID
    var submittedAt: Date
}

extension Category {
    static let sample = Category(
        id: UUID(), name: "Chores", emoji: "🧹",
        colorHex: "#6C5CE7", isDefault: true,
        pointValue: 1, targetCount: 1
    )
}
