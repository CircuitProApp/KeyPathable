import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct KeyPathableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let propertyNames: [String] = declaration.memberBlock.members.compactMap { member in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindings.first?.accessorBlock == nil,
                  let name = varDecl.bindings.first?.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines),
                  varDecl.attributes.contains(where: { $0.description.contains("@KeyPath") })
            else { return nil }
            return name
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
    ]
}
