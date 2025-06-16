//
//  UIAdd-ons.swift
//  ShelfAI
//
//  Created by Krsna  on 6/16/25.
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all) // Ensures gradient fills the entire screen
    }
}


struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                      control1: CGPoint(x: rect.maxX, y: rect.minY + 50),
                      control2: CGPoint(x: rect.maxX - 50, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                      control1: CGPoint(x: rect.maxX, y: rect.maxY - 50),
                      control2: CGPoint(x: rect.midX + 50, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.midY),
                      control1: CGPoint(x: rect.minX, y: rect.maxY - 50),
                      control2: CGPoint(x: rect.minX + 50, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                      control1: CGPoint(x: rect.minX, y: rect.minY + 50),
                      control2: CGPoint(x: rect.midX - 50, y: rect.minY))

        return path
    }
}

