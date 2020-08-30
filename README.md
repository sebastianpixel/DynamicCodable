# DynamicCodable

Swift Property Wrappers based on `Codable` for decoding (and encoding) types that are defined in the (JSON) data that should be decoded.

## Usage
`DynamicCodable` provides a way to (de)serialize types by wrapping them in `DymamicEncodable`, `DymamicDecodable` or their combination `DynamicCodable`. Those types are generic over the wrapped types and expose them as `value` property.
```
struct HomeScreen: Codable {
    let routes: [DynamicCodable<Route>]
    @DynamicCodable var route: Route

    init(routes: [Route], route: Route) {
        self.routes = routes.map(DynamicCodable.init)
        _route = DynamicCodable(route)
    }
}
```
To deserialize a `HomeScreen` the types to decode need to be registered in `DynamicDecodableRegistry`:
```
DynamicDecodableRegistry.register(DetailScreenRoute.self, typeIdentifier: DetailScreenRoute.type)
DynamicDecodableRegistry.register(HomeScreenRoute.self, typeIdentifier: HomeScreenRoute.type)
```

## Example: Routes
In a modularized app where features are separated across multiple modules one might choose to define a module for the feature's interface and one for it's implementation. This would have the benefit of them not directly depending on each other and thus being interchangable and faster to build as features would only import each others' interface. 

Routing in this setup could then be achieved by each feature exposing a `Route` object in it's interface module so other features can refer to it in a type safe way. The feature would then implement a `RoutingHandler` in it's implementation module which returns a view for the route. 

`Route`s are not limited to static use though. If an overview screen has links to various detail screens `Route` objects could be serialized as JSON and decoded in the app. The issue here is that properties might differ from `Route` to `Route`: the `DetailScreenRoute` might need an `id` in contrast to the `HomeScreenRoute`  where there's only one home screen.
```
protocol Route: DynamicCodableProtocol {}

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
[
    {
        "type": "homescreen"
    },
    {
        "type": "detailpage",
        "id": "550121C5-3D8F-4AC8-AB14-BDF7E6D11626"
    }
]
```
Based on the `type` property first a `HomeScreenRoute` should be deserialized, then  a `DetailScreenRoute`.

Swift's `Codable` would require to either define a `struct Route` where all properties but `type` would have to be `Optional`s or - if the JSON is always flat - one could opt for deserializing a `Dictionary<String: String>` instead.

By using `DynamicCodable` the `DetailScreenRouteHandler` from the example above would have access to `DetailScreenRoute`'s `id` property without the need to unwrap an Optional value and get only the information that is needed.

## Constraints
* Types need to be identified in JSON via a field `type` which is the protocol requirement of `DynamicCodableProtocol`.
* Types must be registered in `DynamicDecodableRegistry` (which is then referenced in extensions of Coding Containers) for decoding with an identifier of type String (which is then matched with the value of the `type` field).
