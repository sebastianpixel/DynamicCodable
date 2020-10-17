/// The one location where dynamic type identifiers are mapped
/// to the types that should be decoded.
public final class DynamicDecodableRegistry {
    public typealias DynamicDecodable = TypeIdentifiable & Decodable

    struct NoTypeRegistered: Error {
        let typeIdentifier: String
    }

    private static var types = [String: DynamicDecodable.Type]()

    /// Register a type for dynamic decoding.
    public static func register(_ type: DynamicDecodable.Type, typeIdentifier: String) {
        types[typeIdentifier] = type
    }

    static func type(for typeIdentifier: String) throws -> DynamicDecodable.Type {
        guard let type = types[typeIdentifier] else {
            throw NoTypeRegistered(typeIdentifier: typeIdentifier)
        }
        return type
    }
}
