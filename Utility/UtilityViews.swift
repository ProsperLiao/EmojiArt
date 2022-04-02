//
//  UtilityViews.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/3/1.
//

import SwiftUI


// 语法糖，方便使用 UIImage 可选值来创建 Image
struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        if uiImage != nil {
            Image(uiImage: uiImage!)
        }
    }
}

// 语法糖，方便创建动画化行为的按钮
struct AnimatedActionButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            if title != nil && systemImage != nil {
                Label(title!, systemImage: systemImage!)
            } else if title != nil {
                Text(title!)
            } else if systemImage != nil {
                Image(systemName: systemImage!)
            }
        }
    }
}

// 创建 Identifiable 的 Alert
// 使用 .alert(igtem: $alertToShow) { theIdentifiableAlert in ... }
// alertToShow 是 Binding<IdentifiableAlert>?
// 当需要显示 alert 时
// 只需设置 alertToShow = IdentifiableAlert(id: "my alert") { Alert(title: ...)}
// id 必需是唯一

struct IdentifiableAlert: Identifiable {
    var id: String
    var alert: () -> Alert
}


struct AnimatableSystemFontModifier: Animatable, ViewModifier {
    var size: CGFloat
    
    var animatableData: CGFloat {
        get { size }
        set { size = newValue}
    }
    
    func body(content: Content) -> some View {
        content.font(.system(size: size))
    }
}

extension View {
    func animatableSystemFontModifier(size: CGFloat) -> some View {
        modifier(AnimatableSystemFontModifier(size: size))
    }
}


// undo 和 redo 按钮
struct UndoButton: View {
    let undo: String?
    let redo: String?
    
    @Environment(\.undoManager) var undoManager
    
    var body: some View {
        let canUndo = undoManager?.canUndo ?? false
        let canRedo = undoManager?.canRedo ?? false
        
        if canUndo || canRedo {
            HStack {
                Button {
                    undoManager?.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle")
                }
                .disabled(!canUndo)
                Button {
                    undoManager?.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward.circle")
                }
                .disabled(!canRedo)
            }
            .contextMenu {
                if UIDevice.current.userInterfaceIdiom == .mac {
                    if canUndo {
                        Button {
                            undoManager?.undo()
                        } label: {
                            Label(undo ?? "Undo", systemImage: "arrow.uturn.backward")
                        }
                    }
                    if canRedo {
                        Button {
                            undoManager?.redo()
                        } label: {
                            Label(redo ?? "Redo", systemImage: "arrow.uturn.forward")
                        }
                    }
                }
            }
        }
    }
}

extension UndoManager {
    var optionalUndoMenuItemTitle: String? {
        canUndo ? undoMenuItemTitle : nil
    }
    
    var optionalRedoMenuItemTitle: String? {
        canRedo ? redoMenuItemTitle : nil
    }
}


extension View {
    @ViewBuilder
    func wrappedInNavigationViewToMakeDismissable(_ dismiss: (() -> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            NavigationView {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            self
        }
    }
    
    @ViewBuilder
    func dismissable(_ dismiss: (() -> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
            }
        } else {
            self
        }
    }
}
