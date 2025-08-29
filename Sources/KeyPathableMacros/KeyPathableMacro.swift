import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct KeyPathMarkerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

public struct KeyPathableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let propertyNames: [String] = declaration.memberBlock.members.compactMap { member in
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                varDecl.bindings.first?.accessorBlock == nil
            else { return nil }

            let hasKeyPath = (varDecl.attributes).contains { attr in
                guard let a = attr.as(AttributeSyntax.self) else { return false }
                return a.attributeName.trimmedDescription == "KeyPath"
            }
            guard hasKeyPath else { return nil }

            return varDecl.bindings.first?
                .pattern.trimmedDescription
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 1. Generate the AttributeSource struct (this part is unchanged).
        let staticMembers = propertyNames.map { name in
            "    public static let \(name) = AttributeSource(key: \"\(name)\")"
        }.joined(separator: "\n")

        let attributeSourceStruct: DeclSyntax = """
        public struct AttributeSource: Codable, Hashable, Sendable {
            public let key: String
            private init(key: String) { self.key = key }

            \(raw: staticMembers)
        }
        """

        // 2. Generate the private key path lookup dictionary (the new part).
        guard let rootTypeName = declaration.as(StructDeclSyntax.self)?.name ?? declaration.as(ClassDeclSyntax.self)?.name else {
            // This could be an error diagnostic if the macro is applied to an unsupported type like an enum.
            return []
        }
        
        let keyPathEntries = propertyNames.map { name in
            // Create a dictionary entry mapping the string key to the compile-time KeyPath.
            // Example: `"name": \ComponentDefinition.name`
            "        \"\(name)\": \\\(rootTypeName).\(name)"
        }.joined(separator: ",\n")
        
        let keyPathMap: DeclSyntax = """
        internal static let _keyPathLookup: [String: PartialKeyPath<\(rootTypeName)>] = [
        \(raw: keyPathEntries)
        ]
        """
        
        // 3. Return BOTH generated members.
        return [attributeSourceStruct, keyPathMap]
    }
}

@main
struct KeyPathablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        KeyPathableMacro.self,
        KeyPathMarkerMacro.self
    ]
}
