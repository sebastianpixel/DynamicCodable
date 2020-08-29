import Foundation

public protocol DynamicEncodable: Encodable {
    /// Instance type property necessary for encoding.
    ///
    /// **Important**: default implementations of protocol properties
    /// are computed properties and would therefore not be encoded.
    var type: String { get }
}

public protocol DynamicDecodable: Decodable {
    /// The type identifier of the concrete dynamic codable instance.
    /// Example:
    /// ```
    /// protocol Route: DynamicCodable {}
    ///
    /// public struct DetailPageRoute: Route {
    ///     public static var type = "detailpage"
    ///
    ///     public let id: UUID
    ///     public let type: String // necessary only if type should be encoded as well
    ///
    ///     public init(id: UUID) {
    ///         self.id = id
    ///         type = Self.type
    ///     }
    /// }
    /// ```
    ///
    /// Expected JSON:
    /// ```
    /// {
    ///     "type": "detailpage",
    ///     "id": "550121C5-3D8F-4AC8-AB14-BDF7E6D11626"
    /// }
    /// ```
    static var type: String { get }

    /// A convenience "convention over configuration" property.
    /// This allows for omitting delarations of the expected type identifier
    /// in the JSON data by retrieving it from the type's name.
    /// As default this will just lowercase the name of the implementing type.
    /// Protocols like the `Route` protocol in the example above could for
    /// example override this in extension of `Route`.
    static var typeByNamingConvention: String { get }
}

public extension DynamicDecodable {
    static var type: String {
        typeByNamingConvention
    }

    static var typeByNamingConvention: String {
        "\(self)".lowercased()
    }
}

public typealias DynamicCodable = DynamicEncodable & DynamicDecodable

/// Utility type to retrieve the dynamic type identifier from JSON data
public struct TypeDecodable: Decodable {
    public let type: String
}

/// The one location where dynamic type identifiers are mapped
/// to the types that should be decoded.
public final class DynamicDecodableRegistry {
    private static var types = [String: DynamicDecodable.Type]()

    /// Registers a type for dynamic decoding.
    public static func register(_ type: DynamicDecodable.Type) {
        types[type.type] = type
    }

    /// Returns a previously registered type from a type identifier
    public static func type(for typeIdentifier: String) -> DynamicDecodable.Type {
        guard let type = types[typeIdentifier] else {
            fatalError("Configuration error: no type registered for identifier \(typeIdentifier)")
        }
        return type
    }
}

// Decoding Methods of Keyed- and UnkeyedDecodingContainer that allow for decoding
// the type of a protocol. When implementing a protocol that conforms to `DynamicCodable`
// these methods need to be provided as well as they define how the specific protocol
// type should be decoded.
public extension KeyedDecodingContainer {
    func decode(_ type: [DynamicDecodable].Type, forKey key: K) throws -> [DynamicDecodable] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: [DynamicDecodable].Type, forKey key: K) throws -> [DynamicDecodable]? {
        guard contains(key) else { return nil }
        return try decode(type, forKey: key)
    }

    func decode(_: DynamicDecodable.Protocol, forKey key: K) throws -> DynamicDecodable {
        let decoder = try superDecoder(forKey: key)
        let typeIdentifier = try TypeDecodable(from: decoder).type
        return try DynamicDecodableRegistry.type(for: typeIdentifier).init(from: decoder)
    }

    func decodeIfPresent(_ `protocol`: DynamicDecodable.Protocol, forKey key: K) throws -> DynamicDecodable? {
        guard contains(key) else { return nil }
        return try decode(`protocol`, forKey: key)
    }
}

public extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [DynamicDecodable].Type) throws -> [DynamicDecodable] {
        var array = [DynamicDecodable]()
        while !isAtEnd {
            if let dynamicDecodable = try? decode(DynamicDecodable.self) {
                array.append(dynamicDecodable)
            }
        }
        return array
    }

    mutating func decode(_: DynamicDecodable.Protocol) throws -> DynamicDecodable {
        let decoder = try superDecoder()
        let typeIdentifier = try TypeDecodable(from: decoder).type
        return try DynamicDecodableRegistry.type(for: typeIdentifier).init(from: decoder)
    }
}

// Encoding methods that do not need to be provided for each
// protocol that conforms to `DynamicCodable`.
public extension UnkeyedEncodingContainer {
    mutating func encode(_ value: [DynamicEncodable]) throws {
        try value.forEach { try encode($0) }
    }

    mutating func encode(_ value: DynamicEncodable) throws {
        try value.encode(to: superEncoder())
    }

    mutating func encodeIfPresent(_ value: [DynamicEncodable]?) throws {
        guard let value = value else { return }
        try encode(value)
    }

    mutating func encodeIfPresent(_ value: DynamicEncodable?) throws {
        guard let value = value else { return }
        try encode(value)
    }
}

public extension KeyedEncodingContainer {
    mutating func encode(_ value: DynamicEncodable, forKey key: K) throws {
        try value.encode(to: superEncoder(forKey: key))
    }

    mutating func encode(_ value: [DynamicEncodable], forKey key: K) throws {
        var container = nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: DynamicEncodable?, forKey key: K) throws {
        guard let value = value else { return }
        try value.encode(to: superEncoder(forKey: key))
    }

    mutating func encodeIfPresent(_ value: [DynamicEncodable]?, forKey key: K) throws {
        guard let value = value else { return }
        try encode(value, forKey: key)
    }
}
