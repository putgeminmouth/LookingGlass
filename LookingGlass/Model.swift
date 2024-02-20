import Foundation
import SwiftUI

protocol Copyable {}

extension Copyable {
    func changing<T>(path: WritableKeyPath<Self, T>, to value: T) -> Self {
        var clone = self
        clone[keyPath: path] = value
        return clone
    }
    func copy(update: (inout Self) -> Void) -> Self {
        var copy = self
        update(&copy)
        return copy
    }}

struct DisplayMode: Copyable, Hashable {
    let id: String = UUID().uuidString
    var widthPixels: UInt
    var heightPixels: UInt
    var refreshRateHz: Double
}
struct DisplayConfig: Copyable {
    var id: UInt32
    var name: String?
    var productId: UInt32
    var vendorId: UInt32
    var serialNumber: UInt32
    var widthInMillimeters: UInt32
    var heightInMillimeters: UInt32
    var maxWidthPixels: UInt32
    var maxHeightPixels: UInt32
    var displayModes: [DisplayMode]
}
struct GlassConfig: Copyable {
    var id: String
    var name: String?
    var displayConfig: DisplayConfig
    var registered: Bool
    var active: Bool
    var renderWidthPixels: UInt32?
    var renderHeightPixels: UInt32?
    var renderDelaySeconds: Float32
    var windowWidthPixels: UInt32
    var windowHeightPixels: UInt32
}
extension DisplayMode: Codable {}
extension DisplayConfig: Codable, Hashable {}
extension GlassConfig: Codable, Hashable {}

// $glassConfigs[index].displayConfig.name
// $glassConfigs[index].displayConfig.map($0.name, $0.name = $1)
extension Binding {
    func map<U>(_ g: @escaping (Self) -> U, _ s: @escaping (Self, U) -> Void) -> Binding<U> {
        return Binding<U>(
            get: { g(self) },
            set: { s(self, $0) }
        )
    }
}

extension Binding {
    func asString(format: @escaping (Value) -> String, parse: @escaping (String) -> Value?) -> Binding<String> {
        return Binding<String>(
            get: { format(wrappedValue) },
            set: { wrappedValue = parse($0) ?? wrappedValue }
        )
    }
}
extension Binding where Value == UInt32 {
    func asString() -> Binding<String> { asString(format: {String($0)}, parse: {UInt32($0)}) }
}
extension Binding where Value == UInt {
    func asString() -> Binding<String> { asString(format: {String($0)}, parse: {UInt($0)}) }
}
extension Binding where Value == Int {
    func asString() -> Binding<String> { asString(format: {String($0)}, parse: {Int($0)}) }
}
extension Binding where Value == Float32 {
    func asString() -> Binding<String> { asString(format: {String($0)}, parse: {Float32($0)}) }
}
extension Binding where Value == Double {
    func asString() -> Binding<String> { asString(format: {String($0)}, parse: {Double($0)}) }
}
extension Binding where Value == Bool {
    func onlyIf(_ rhs: Binding<Bool>) -> Binding<Bool> {
        return Binding<Bool>(
            get: { wrappedValue && rhs.wrappedValue },
            set: { if rhs.wrappedValue {wrappedValue = $0} }
        )
    }
}
extension Binding where Value == Optional<Any> {
//    func asString<T>() -> Binding<String> { asString(format: {String($0)}, parse: {T($0)}) }
}

prefix func ~<T>(_ lhs: Binding<T>) -> T {
    lhs.wrappedValue
}

func ??<T>(_ lhs: Binding<T?>, _ rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

struct AppSettings {
    var automaticUnregisterDelayInSeconds: Int? = nil
}
extension AppSettings: Codable, Copyable {}

extension Optional: RawRepresentable where Wrapped: Codable {
    public init?(rawValue: String) {
        guard let value = try? JSONDecoder().decode(Self.self, from: Data(rawValue.utf8)) else {
            return nil
        }
        self = value
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self) else {
            return "{}"
        }
        return String(decoding: data, as: UTF8.self)
    }

}

extension NSScreen {
    var displayId: UInt32? {
        return self.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32
    }
}

extension String {
    func nonEmptyOrNil() -> String? {
        return self.isEmpty ? nil: self
    }
}
