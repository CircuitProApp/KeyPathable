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
                // ignore already-computed properties
                varDecl.bindings.first?.accessorBlock == nil
            else { return nil }

            // Look for our marker attribute robustly
            let hasKeyPath = (varDecl.attributes).contains { attr in
                guard let a = attr.as(AttributeSyntax.self) else { return false }
                return a.attributeName.trimmedDescription == "KeyPath"
            }
            guard hasKeyPath else { return nil }

            return varDecl.bindings.first?
                .pattern.trimmedDescription
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

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

        return [attributeSourceStruct]
    }
}

@main
struct KeyPathablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        KeyPathableMacro.self,
        KeyPathMarkerMacro.self
    ]
}
