//
//  PointsEngine.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import Foundation
import SwiftData

enum PointsEngine {
    /// Call after marking `completion.approved = true`
    static func awardIfThresholdCrossed(for completion: Completion, in context: ModelContext) throws {
        guard
            let member = completion.member,
            let category = completion.category,
            completion.approved == true
        else { return }

        // capture values for the predicate (no global calls inside #Predicate)
        let memberID = member.id
        let categoryID = category.id

        let fetch = FetchDescriptor<Completion>(
            predicate: #Predicate { c in
                c.member?.id == memberID &&
                c.category?.id == categoryID &&
                c.approved == true
            }
        )

        let afterCount = try context.fetch(fetch).count
        let beforeCount = max(0, afterCount - 1)

        let t = max(1, category.targetCount)
        let completedSetsBefore = beforeCount / t
        let completedSetsAfter  = afterCount / t
        let newAwards = completedSetsAfter - completedSetsBefore

        if newAwards > 0 {
            member.points += newAwards * category.pointsPerAward
        }
    }
}
