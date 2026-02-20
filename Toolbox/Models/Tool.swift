import Foundation

struct EnvironmentVar: Codable, Identifiable {
    var id: String { name }
    let name: String   // e.g. "ANTHROPIC_API_KEY"
    let label: String  // e.g. "Anthropic API Key"
}

struct Tool: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let icon: String
    let description: String
    let command: String
    let arguments: [Argument]
    let flags: [Flag]
    let environment: [EnvironmentVar]?

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: Tool, rhs: Tool) -> Bool {
        lhs.name == rhs.name
    }
}

struct Argument: Codable, Identifiable {
    var id: String { name }
    let name: String
    let label: String
    let type: ArgumentType
    let required: Bool
    let placeholder: String?
    let `default`: String?

    enum CodingKeys: String, CodingKey {
        case name, label, type, required, placeholder
        case `default` = "default"
    }
}

struct Flag: Codable, Identifiable {
    var id: String { name }
    let name: String
    let flag: String
    let label: String
    let type: FlagType
    let `default`: FlagDefault?

    enum CodingKeys: String, CodingKey {
        case name, flag, label, type
        case `default` = "default"
    }
}

enum ArgumentType: String, Codable {
    case string
    case directory
    case file
    case bool
}

enum FlagType: String, Codable {
    case bool
    case string
}

enum FlagDefault: Codable {
    case bool(Bool)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                FlagDefault.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Bool or String")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        }
    }

    var boolValue: Bool {
        switch self {
        case .bool(let v): return v
        default: return false
        }
    }

    var stringValue: String {
        switch self {
        case .string(let v): return v
        default: return ""
        }
    }
}
