//
//  CornerBracket.swift
//  ExpiryScanner
//
//  Created by Victor Chandra on 16/06/25.
//

import SwiftUI

/// A custom shape for the L-shaped corner brackets of the scanner frame.
struct CornerBracket: Shape {
    var corner: UIRectCorner
    var lineLength: CGFloat = 50
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch corner {
        case.topLeft:
            path.move(to: CGPoint(x: 0, y: lineLength))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: lineLength, y: 0))
        case.topRight:
            path.move(to: CGPoint(x: rect.width - lineLength, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: lineLength))
        case.bottomLeft:
            path.move(to: CGPoint(x: lineLength, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - lineLength))
        case.bottomRight:
            path.move(to: CGPoint(x: rect.width, y: rect.height - lineLength))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - lineLength, y: rect.height))
        default:
            break
        }
        
        return path
    }
}
