//
//  Haptics.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import UIKit

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func lightTap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
