// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that generates a nested `AttributeSource` struct from properties
/// marked with `@KeyPath`, enabling type-safe, autocompletable access.
@attached(member, names: named(AttributeSource))
public macro KeyPathable() = #externalMacro(module: "KeyPathableMacros", type: "KeyPathableMacro")

/// A property wrapper to mark a property as an accessible key path,
/// for use with the `@KeyPathable` macro.
@propertyWrapper
public struct KeyPath<Value> {
    // It now has real storage.
    public var wrappedValue: Value

    // The initializer now correctly stores the value.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
