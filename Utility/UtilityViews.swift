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

