//
//  UtilityExtensions.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/3/1.
//

import SwiftUI

// 在 Identifiables 的 Collection 中，
// 获取与某元素 id 匹配的首个元素的 index.
// 预设该 Collection 中的的 Identifiable 元素唯一，

extension Collection where Element: Identifiable {
    func index(matching element: Element) -> Self.Index? {
        firstIndex(where: { $0.id == element.id })
    }
}

// 扩展 Collection 的可变子类 RangeReplaceableCollection,
// 增加一些工具方法，操控集合

extension RangeReplaceableCollection where Element: Identifiable {
    // 移除集合中某元素，预设元素唯一
    mutating func remove(_ element: Element) {
        if let index = index(matching: element) {
            remove(at: index)
        }
    }

    // 使用 Identifiable 的元素作为下标，获取集合中的元素，或替换为新元素.
    // 取值时，如果集合中存在，则返回集合中的元素; 集合中不存在，则返回下标元素.
    // 设值时，只有集合中存在 id 匹配的元素时，才替换为新元素
    subscript(_ element: Element) -> Element {
        get {
            if let index = index(matching: element) {
                return self[index]
            } else {
                return element
            }
        }
        set {
            if let index = index(matching: element) {
                replaceSubrange(index ... index, with: [newValue])
            }
        }
    }
}

extension Set where Element: Identifiable {
    // 往 Set 中加入或删除某元素
    mutating func toggleMembership(of element: Element) {
        if let index = index(matching: element) {
            remove(at: index)
        } else {
            insert(element)
        }
    }
}

extension String {
    // 移除字符串中的重复字符
    var withNoRepeatedCharacters: String {
        var uniqued = ""
        for ch in self {
            if !uniqued.contains(ch) {
                uniqued.append(ch)
            }
        }
        return uniqued
    }
}

extension Character {
    var isEmoji: Bool {
        // Swift 并不提供字符的 isEmoji 方法
        // 但它允许我们检查字符的 component scalars isEmoji
        // 不幸地 unicode 允许特定的 scalars (例如 1)
        // 被其他 scalar 修改为 emoji (例如1️⃣)
        // 所以 scalar "1" 的 isEmoji = true
        // 所以我们不能只检查第一个 scalar isEmoji
        // 这里快速简单的方法是检查 scalar 是否不小于我们所知道的第一个真正的 emoji "0x238d"
        // 或者检查字符是否是一个多 scalar 的 unicode 序列
        // (例如，1 加上 unicode 修饰符，就补强制呈现为 emoji 1️⃣)

        if let firstScalar = unicodeScalars.first, firstScalar.properties.isEmoji {
            return (firstScalar.value >= 0x238D || unicodeScalars.count > 1)
        } else {
            return false
        }
    }
}

// 从可能存在其他信息的 url 中, 提取实际的图片 url
// (查找 imgurl 关键字)
// imgurl 是常用的关键字，用于把实际图片 url 嵌入于 url 中

extension URL {
    var imageURL: URL {
        for query in query?.components(separatedBy: "&") ?? [] {
            let queryComponents = query.components(separatedBy: "=")
            if queryComponents.count == 2 {
                if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                    return url
                }
            }
        }
        return baseURL ?? self
    }
}

// 为拖拽手势添加便利方法，用于计算拖拽的距离

extension DragGesture.Value {
    var distance: CGSize { location - startLocation }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

// 定义一些运算符，用于操作CGPoint 和 CGSize
extension CGPoint {
    static func - (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.x - rhs.x, height: lhs.y - rhs.y)
    }

    static func + (lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }

    static func - (lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }

    static func * (lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func / (lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

extension CGSize {
    // 获取CGSize 的中点
    var center: CGPoint {
        CGPoint(x: width / 2, y: height / 2)
    }

    static func + (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func - (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    static func * (lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    static func / (lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
}

// 增加 CGSize 和 CGFloat 遵从协议 RawRepresentable
// 以使它们能使用 @SceneStorage
// 为实现这个目的，首先在 RawRepresentable 协议，且同时遵从Codable 协议(CGFloat 和 CGSize 都遵从此协议)时，
// 提供 rawValue 和 init(rawValue:) 的默认实现，
// 然后只需要把 Codable 的类型声明为遵从 RawRepresentable, 它就会获得此默认的实现

extension RawRepresentable where Self: Codable {
    public var rawValue: String {
        if let json = try? JSONEncoder().encode(self), let string = String(data: json, encoding: .utf8) {
            return string
        } else {
            return ""
        }
    }

    public init?(rawValue: String) {
        if let value = try? JSONDecoder().decode(Self.self, from: Data(rawValue.utf8)) {
            self = value
        } else {
            return nil
        }
    }
}

extension CGSize: RawRepresentable { }
extension CGFloat: RawRepresentable { }


// 用于[NSItemProvider] (NSItemProvider 数组) 的便利方法，
// 使从 providers 加载对象的代码简单一些.
// NSItemProvider 是从 Objective-C (pre-Swift）遗留来的

extension Array where Element == NSItemProvider {
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            provider.loadObject(ofClass: theType) { object, _ in
                if let value = object as? T {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }

    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            _ = provider.loadObject(ofClass: theType) { object, _ in
                if let value = object {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }

    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }

    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
}
