//
//  Member.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import Foundation
import SwiftData
import SwiftUI

@Model
final class Member {
    @Attribute(.unique) var id: UUID
    var name: String
    var roleRaw: String
    var avatarEmoji: String
    var points: Int
    @Relationship(deleteRule: .cascade) var purchases: [Purchase]

    var role: Role {
        get { Role(rawValue: roleRaw) ?? .child }
        set { roleRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), name: String, role: Role, avatarEmoji: String = "🙂", points: Int = 0) {
        self.id = id
        self.name = name
        self.roleRaw = role.rawValue
        self.avatarEmoji = avatarEmoji
        self.points = points
        self.purchases = []
    }
}

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    /// how many approved completions required to earn points
    var targetCount: Int
    /// points granted each time the targetCount is reached
    var pointsPerAward: Int
    var isActive: Bool

    init(id: UUID = UUID(), name: String, icon: String = "✅", targetCount: Int = 5, pointsPerAward: Int = 2, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.icon = icon
        self.targetCount = max(1, targetCount)
        self.pointsPerAward = max(0, pointsPerAward)
        self.isActive = isActive
    }
}

@Model
final class Completion {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// nil = pending, true = approved, false = declined
    var approved: Bool?
    @Relationship var member: Member?
    @Relationship var category: Category?

    init(id: UUID = UUID(), date: Date = .now, approved: Bool? = nil, member: Member, category: Category) {
        self.id = id
        self.date = date
        self.approved = approved
        self.member = member
        self.category = category
    }
}

@Model
final class Purchase {
    @Attribute(.unique) var id: UUID
    var itemName: String
    var pointsSpent: Int
    var date: Date
    var photoData: Data?
    @Relationship var member: Member?

    init(id: UUID = UUID(), itemName: String, pointsSpent: Int, date: Date = .now, photoData: Data? = nil, member: Member) {
        self.id = id
        self.itemName = itemName
        self.pointsSpent = pointsSpent
        self.date = date
        self.photoData = photoData
        self.member = member
    }
}

extension Image {
    static func fromPurchase(_ p: Purchase) -> Image {
        if let data = p.photoData, let ui = UIImage(data: data) { return Image(uiImage: ui) }
        return Image(systemName: "photo")
    }
}
