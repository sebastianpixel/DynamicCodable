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

private struct CustomCodingKey: CodingKey {
    var stringValue: String

    init(_ string: String) {
        stringValue = string
        intValue = Int(string)
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = Int(stringValue)
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
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
        if let encodable = wrappedValue as? Encodable {
            var container = encoder.singleValueContainer()
            try encodable.encode(to: &container)
        } else if let encodableArray = wrappedValue as? [Encodable] {
            var container = encoder.unkeyedContainer()
            try encodableArray.encode(to: &container)
        } else if let encodableDictionary = wrappedValue as? [AnyHashable: Encodable] {
            var container = encoder.container(keyedBy: CustomCodingKey.self)
            for (key, value) in encodableDictionary {
                let codingKey = CustomCodingKey("\(key.base)")
                try value.encode(for: codingKey, to: &container)
            }
        } else if let optional = wrappedValue as? OptionalProtocol, optional.isNil {
            return
        } else {
            throw Error.encodingFailed("\(Value.self) must conform to Encodable.")
        }
    }
}

private protocol OptionalProtocol {
    var isNil: Bool { get }
}
extension Optional: OptionalProtocol {
    var isNil: Bool {
        if case .none = self {
            return true
        }
        return false
    }
}

private extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }

    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(self)
    }

    func encode<K: CodingKey>(for key: K, to container: inout KeyedEncodingContainer<K>) throws {
        try container.encode(self, forKey: key)
    }
}

private extension Array where Element == Encodable {
    func encode(to container: inout UnkeyedEncodingContainer) throws {
        try forEach { try $0.encode(to: &container) }
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

    private typealias OptionalType = (OptionalProtocol & ExpressibleByNilLiteral).Type

    public enum Error: Swift.Error {
        case decodingFailed(String)
    }

    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let value: Any
        if var unkeyedContainer = try? decoder.unkeyedContainer() {
            var array = [DynamicDecodable<Any>]()
            while !unkeyedContainer.isAtEnd {
                try array.append(unkeyedContainer.decode(DynamicDecodable<Any>.self))
            }
            value = array.map(\.wrappedValue)

        } else {
            let createKeyedContainer = { try decoder.container(keyedBy: CustomCodingKey.self) }

            if let optional = Value.self as? OptionalType, (try? createKeyedContainer()) == nil {
                value = optional.init(nilLiteral: ())

            } else if let optional = Value.self as? OptionalType,
                      let container = try? createKeyedContainer(), container.allKeys.isEmpty {
                value = optional.init(nilLiteral: ())

            } else {
                let container = try createKeyedContainer()

                // If a typeIdentifier can be retrieved `Value` is of type `DynamicDecodable`
                // else it might be a `Dictionary<AnyHashable: DynamicDecodable<Any>>`.
                if let typeIdentifier = try? container.decode(String.self, forKey: .init("type")) {
                    guard let type = DynamicDecodableRegistry.type(for: typeIdentifier) else {
                        throw Error.decodingFailed("Configuration error: no type registered for identifier \(typeIdentifier) in \(DynamicDecodableRegistry.self).")
                    }
                    value = try type.init(from: decoder)

                } else {
                    value = try container.allKeys.reduce(into: [AnyHashable: Any]()) {
                        $0[$1.stringValue] = try container.decode(DynamicDecodable<Any>.self, forKey: $1).wrappedValue
                    }
                }
            }
        }

        if let value = value as? Value {
            self.init(wrappedValue: value)
        } else {
            throw Error.decodingFailed("Could not cast type \(type(of: value)) to \(Value.self)")
        }
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
