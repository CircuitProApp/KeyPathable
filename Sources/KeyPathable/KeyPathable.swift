// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A marker attribute to indicate that a property is an accessible key path,
/// for use with the `@KeyPathable` macro.
@attached(peer) // marker; generates no code
public macro KeyPath() = #externalMacro(module: "KeyPathableMacros", type: "KeyPathMarkerMacro")

/// Generates the nested `AttributeSource` type.
@attached(member, names: named(AttributeSource), named(_keyPath))
public macro KeyPathable() = #externalMacro(module: "KeyPathableMacros", type: "KeyPathableMacro")
