import Foundation
import DynamicCodable

protocol Route: DynamicCodable {}

extension Route {
    static var typeByNamingConvention: String {
        "\(self)".replacingOccurrences(of: "\(Route.self)", with: "").lowercased()
    }
}

// Extensions of Keyed- and UnkeyedDecodingContainer necessary for each protocol
// that conforms to `DynamicCodable` as they directly refer to the protocol type to decode.
extension KeyedDecodingContainer {
    func decode(_ type: [Route].Type, forKey key: K) throws -> [Route] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: [Route].Type, forKey key: K) throws -> [Route]? {
        guard contains(key) else { return nil }
        return try decode(type, forKey: key)
    }

    func decode(_: Route.Protocol, forKey key: K) throws -> Route {
        let decoder = try superDecoder(forKey: key)
        let typeIdentifier = try TypeDecodable(from: decoder).type
        // swiftlint:disable:next force_cast
        return try DynamicDecodableRegistry.type(for: typeIdentifier).init(from: decoder) as! Route
    }

    func decodeIfPresent(_ `protocol`: Route.Protocol, forKey key: K) throws -> Route? {
        guard contains(key) else { return nil }
        return try decode(`protocol`, forKey: key)
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Route].Type) throws -> [Route] {
        var array = [Route]()
        while !isAtEnd {
            if let dynamicCodable = try? decode(Route.self) {
                array.append(dynamicCodable)
            }
        }
        return array
    }

    mutating func decode(_: Route.Protocol) throws -> Route {
        let decoder = try superDecoder()
        let typeIdentifier = try TypeDecodable(from: decoder).type
        // swiftlint:disable:next force_cast
        return try DynamicDecodableRegistry.type(for: typeIdentifier).init(from: decoder) as! Route
    }
}
