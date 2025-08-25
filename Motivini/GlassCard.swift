//
//  GlassCard.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI

struct GlassCard<Content: View>: View {
    var content: () -> Content
    var corner: CGFloat = 24

    init(corner: CGFloat = 24, @ViewBuilder content: @escaping () -> Content) {
        self.corner = corner
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .stroke(LinearGradient(colors: [
                        .white.opacity(0.7), .white.opacity(0.1)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 8)
    }
}
