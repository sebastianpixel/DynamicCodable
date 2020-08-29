import Foundation

public protocol DynamicCodable {
    /// Instance type property necessary for retrieving the type to
    /// decode and encoding it for later re-decoding.
    ///
    /// **Important**: default implementations of protocol properties
    /// are computed properties and would therefore not be encoded.
    var type: String { get }
}

/// The one location where dynamic type identifiers are mapped
/// to the types that should be decoded.
public final class DynamicDecodableRegistry {
    public typealias DynamicDecodable = DynamicCodable & Decodable

    private static var types = [String: DynamicDecodable.Type]()

    /// Register a type for dynamic decoding.
    public static func register(_ type: DynamicDecodable.Type, typeIdentifier: String) {
        types[typeIdentifier] = type
    }

    fileprivate static func type(for typeIdentifier: String) -> DynamicDecodable.Type? {
        types[typeIdentifier]
    }
}

public struct AnyEncodable<Value>: Encodable {

    public enum Error: Swift.Error {
        case encodingFailed(String)
    }

    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let encodable = value as? Encodable else {
            throw Error.encodingFailed("\(Value.self) must implement Encodable in order to be wrapped in AnyCodable")
        }
        try encodable.encode(to: &container)
    }
}

private extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}

extension AnyEncodable: Equatable {
    public static func == (lhs: AnyEncodable<Value>, rhs: AnyEncodable<Value>) -> Bool {
        let jsonEncoder = JSONEncoder()
        return (try? jsonEncoder.encode(lhs) == jsonEncoder.encode(rhs)) ?? false
    }
}

public struct AnyDecodable<Value>: Decodable {

    public enum Error: Swift.Error {
        case decodingFailed(String)
    }

    private enum CodingKeys: CodingKey {
        case type
    }

    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeIdentifier = try container.decode(String.self, forKey: .type)
        guard let type = DynamicDecodableRegistry.type(for: typeIdentifier) else {
            throw Error.decodingFailed("Configuration error: no type registered for identifier \(typeIdentifier) in AnyDecodableRegistry.")
        }
        let decodable = try type.init(from: decoder)
        guard let value = decodable as? Value else {
            throw Error.decodingFailed("Could not cast type \(Swift.type(of: decodable)) to \(Value.self)")
        }
        self.init(value)
    }
}

extension AnyDecodable: Equatable where Value: Equatable {}

public struct AnyCodable<Value>: Codable {

    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }

    private enum CodingKeys: CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let anyDecodable = try AnyDecodable<Value>(from: decoder)
        self.init(anyDecodable.value)
    }

    public func encode(to encoder: Encoder) throws {
        let value = AnyEncodable(self.value).value
        // swiftlint:disable:this force_cast
        let encodable = value as! Encodable
        var container = encoder.singleValueContainer()
        try encodable.encode(to: &container)
    }
}

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable<Value>, rhs: AnyCodable<Value>) -> Bool {
        AnyEncodable(lhs) == AnyEncodable(rhs)
    }
}
