import Foundation

public protocol DynamicCodableProtocol {
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
    public typealias DynamicDecodable = DynamicCodableProtocol & Decodable

    private static var types = [String: DynamicDecodable.Type]()

    /// Register a type for dynamic decoding.
    public static func register(_ type: DynamicDecodable.Type, typeIdentifier: String) {
        types[typeIdentifier] = type
    }

    fileprivate static func type(for typeIdentifier: String) -> DynamicDecodable.Type? {
        types[typeIdentifier]
    }
}

@propertyWrapper
public struct DynamicEncodable<Value>: Encodable {

    public enum Error: Swift.Error {
        case encodingFailed(String)
    }

    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let encodable = wrappedValue as? Encodable else {
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

extension DynamicEncodable: Equatable {
    public static func == (lhs: DynamicEncodable<Value>, rhs: DynamicEncodable<Value>) -> Bool {
        let jsonEncoder = JSONEncoder()
        return (try? jsonEncoder.encode(lhs) == jsonEncoder.encode(rhs)) ?? false
    }
}

@propertyWrapper
public struct DynamicDecodable<Value>: Decodable {

    public enum Error: Swift.Error {
        case decodingFailed(String)
    }

    private enum CodingKeys: CodingKey {
        case type
    }

    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
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
        self.init(wrappedValue: value)
    }
}

extension DynamicDecodable: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

@propertyWrapper
public final class DynamicCodable<Value>: Codable {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    private enum CodingKeys: CodingKey {
        case type
    }

    required public convenience init(from decoder: Decoder) throws {
        try self.init(wrappedValue: DynamicDecodable<Value>(from: decoder).wrappedValue)
    }

    public func encode(to encoder: Encoder) throws {
        try DynamicEncodable(wrappedValue: self.wrappedValue).encode(to: encoder)
    }
}

extension DynamicCodable: Equatable {
    public static func == (lhs: DynamicCodable<Value>, rhs: DynamicCodable<Value>) -> Bool {
        DynamicEncodable(wrappedValue: lhs) == DynamicEncodable(wrappedValue: rhs)
    }
}
