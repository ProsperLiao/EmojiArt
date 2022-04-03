//
//  CompactableIntoMenu.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/4/2.
//

import SwiftUI

struct CompactableIntoMenu: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var compact: Bool { horizontalSizeClass == .compact }
    
    func body(content: Content) -> some View {
        if compact {
            Menu {
                content
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        } else {
            content
        }
    }
}

extension View {
    func compactableToolbar<Content>(@ViewBuilder content: () -> Content) -> some View where Content: View {
        self.toolbar {
            content().modifier(CompactableIntoMenu())
        }
    }
}
