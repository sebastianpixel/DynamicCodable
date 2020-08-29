# DynamicCodable

Extensions of Swift's `Codable` for decoding (and encoding) where concrete types are depending on JSON data.

## Example: Routes
In a modularized app where features are separated across multiple modules one might choose to define a module for the feature's interface and one for it's implementation. This would have the benefit of them not directly depending on each other and thus being interchangable and faster to build as features would only import each others' interface. 

Routing in this setup could then be achieved by each feature exposing a `Route` object in it's interface module so other features can refer to it in a type safe way. The feature would then implement a `RoutingHandler` in it's implementation module which returns a view for the route. 

`Route`s are not limited to static use though. If an overview screen has links to various detail screens `Route` objects could be serialized as JSON and decoded in the app. The issue here is that properties might differ from `Route` to `Route`: the `DetailScreenRoute` might need an `id` in contrast to the `HomeScreenRoute`  where there's only one home screen.
```
protocol Route: DynamicCodable {}

protocol RouteHandler {
    associatedtype ConcreteRoute: Route
    associatedtype Content: View
    func view(for route: ConcreteRoute) -> Content
}

protocol Router {
    func route(_ route: Route)
    func register<Handler: RouteHandler>(_ handler: Handler)
}

// Interface module "HomeScreen" 
struct HomeScreenRoute: Route, Equatable {
    let type: String

    init() {
        self.type = Self.typeByNamingConvention
    }
}

// Implementation module "HomeScreenImplementation"
struct HomeScreenRouteHandler: RouteHandler {
    func view(for route: HomeScreenRoute) -> Color {
        .red
    }
}

// Interface module "DetailScreen"
struct DetailScreenRoute: Route, Equatable {
    let type: String
    let id: UUID

    init(id: UUID) {
        self.type = Self.typeByNamingConvention
        self.id = id
    }
}

// Implementation module "DetailScreenImplementation"
struct DetailScreenRouteHandler: RouteHandler {
    func view(for route: DetailScreenRoute) -> Color {
        .blue
    }
}
```
The JSON for such `Route`s could look like this:
```
[{
    "type": "homescreen"
},
{
    "type": "detailpage",
    "id": "550121C5-3D8F-4AC8-AB14-BDF7E6D11626"

}]
```
Based on the `type` property first a `HomeScreenRoute` should be deserialized, then  a `DetailScreenRoute`.

Swift's `Codable` would require to either define a `struct Route` where all properties but `type` would have to be `Optional`s or - if the JSON is always flat - one could opt for deserializing a `Dictionary<String: String>` instead.

As an alternative `DynamicCodable` provides a way to (de)serialize types that are defined by implementing `DynamicEncodable`, `DynamicDecodable` or their combination `DynamicCodable`. In the example above `DetailScreenRouteHandler` would have access to `DetailScreenRoute`'s `id` property without the need to unwrap an Optional value and get only the information that is needed. 

## Constraints
* Types need to be identified in JSON via a field `type`.
* Types must be registered in `DynamicDecodingRegistry` (which is then referenced in extensions of Coding Containers).
* To decode objects based on a common protocol `UnkeyedDecodingContainer` and `KeyedDecodingContainer` have to be extended for each such protocol as it's not possible to specifiy protocol types as generic parameters. Ideally this could be resolved for example by a type erased `AnyDynamicDecodable` type in an upcoming version. This extensions look like the following for `Route`:
```
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
```
