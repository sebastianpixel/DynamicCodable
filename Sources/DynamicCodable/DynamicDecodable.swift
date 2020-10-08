@propertyWrapper
public struct DynamicDecodable<Value>: Decodable {

    private typealias OptionalType = (OptionalProtocol & ExpressibleByNilLiteral).Type

    private struct Empty: Decodable {}

    public var wrappedValue: Value

    public init(from decoder: Decoder) throws {
        let value: Any
        let logError: (DynamicDecodableRegistry.NoTypeRegistered) -> Void = {
            print("Configuration error: no type registered for identifier \"\($0.typeIdentifier)\" in \(DynamicDecodableRegistry.self).")
        }
        if var unkeyedContainer = try? decoder.unkeyedContainer() {
            var array = [DynamicDecodable<Any>]()
            while !unkeyedContainer.isAtEnd {
                do {
                    try array.append(unkeyedContainer.decode(DynamicDecodable<Any>.self))
                } catch let error as DynamicDecodableRegistry.NoTypeRegistered {
                    logError(error)
                    // necessary to avoid infinite loop
                    _ = try unkeyedContainer.decode(Empty.self)
                }
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
                    let type = try DynamicDecodableRegistry.type(for: typeIdentifier)
                    value = try type.init(from: decoder)

                } else {
                    value = try container.allKeys.reduce(into: [AnyHashable: Any]()) {
                        do {
                            $0[$1.stringValue] = try container.decode(DynamicDecodable<Any>.self, forKey: $1).wrappedValue
                        } catch let error as DynamicDecodableRegistry.NoTypeRegistered {
                            logError(error)
                        }
                    }
                }
            }
        }

        if let value = value as? Value {
            wrappedValue = value
        } else {
            throw DecodingError.typeMismatch(
                Value.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Could not cast type \(type(of: value))."
                )
            )
        }
    }
}

extension DynamicDecodable: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

extension DynamicDecodable: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
