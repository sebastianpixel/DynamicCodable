# DynamicCodable

Swift Property Wrappers based on `Codable` for decoding (and encoding) types that are defined in the (JSON) data that should be decoded.

`DynamicCodable` provides a way to (de)serialize properties by wrapping them in `@DymamicEncodable`, `@DymamicDecodable` or their combination `@DynamicCodable`.

## Example: Routes
```
protocol Route: DynamicCodableProtocol {}

struct HomeScreen: Codable {
    @DynamicCodable var `self`: Route
    @DynamicCodable var routes: [Route]
    @DynamicCodable var someRouteDict: [String: Route]
}
```
The JSON for `HomeScreen` might look like this:
```
{
    "self": {
        "type": "homescreen"
    },
    "routes": [
        {
            "type": "homescreen"
        },
        {
            "type": "detailpage",
            "id": "550121C5-3D8F-4AC8-AB14-BDF7E6D11626"
        }
    ],
    "someRouteDict": {
        "profilescreen": {
            "type": "profilescreen",
            "id": "84874B0F-1F41-4380-B3C6-CC53A0DE5453",
            "tracking": {
                "some_tracking_service": {
                    "some_tracking_property": "some_tracking_value"
                }
            }
        }
    }
}
```
`Route`s have the field `type` in common (which also is the single requirement of `DynamicCodableProtocol`) which identifies the actual type that should be deserialized. In order for this to work types have to be registered in `DynamicDecodableRegistry` with their respective identifier.
```
DynamicDecodableRegistry.register(DetailScreenRoute.self, typeIdentifier: DetailScreenRoute.type)
DynamicDecodableRegistry.register(HomeScreenRoute.self, typeIdentifier: HomeScreenRoute.type)
DynamicDecodableRegistry.register(ProfileScreenRoute.self, typeIdentifier: ProfileScreenRoute.type)
```
To deserialize JSON like above with Swift's `Codable` alone one could define a `Route` struct that has all possible JSON fields as optional properties defined in a single place. In a modularized setup where routing targets / features like a detail screen or the home screen are separated in different modules this might not be the ideal solution. An alternative could be to not use models for routes alltogether and just deserialize dictionaries.

By using `DynamicCodable` Swift's type system can be leveraged to create clean interfaces with types that define individual optional and non-optional properties. In a possible routing setup like to following `DetailScreenRouteHandler` would have access to `DetailScreenRoute`'s `id` property without the need to unwrap an optional value and get only the information that is needed.
```
protocol RouteHandler {
    associatedtype ConcreteRoute: Route
    associatedtype Content: View
    func view(for route: ConcreteRoute) -> Content
}

protocol Router {
    func callAsFunction(_ route: Route)
    func register<Handler: RouteHandler>(_ handler: Handler)
}

// Interface module "HomeScreen" 
struct HomeScreenRoute: Route {
    static let type = "homescreen"

    let type: String
}

// Implementation module "HomeScreenImplementation"
struct HomeScreenRouteHandler: RouteHandler {
    func view(for route: HomeScreenRoute) -> Color {
        .red
    }
}

// Interface module "DetailScreen"
struct DetailScreenRoute: Route {
    static let type = "homescreen"

    let type: String
    let id: UUID
}

// Implementation module "DetailScreenImplementation"
struct DetailScreenRouteHandler: RouteHandler {
    func view(for route: DetailScreenRoute) -> Color {
        .blue
    }
}
```
## Constraints
* Types need to be identified in JSON via a field `type` which is the protocol requirement of `DynamicCodableProtocol`.
* Types must be registered in `DynamicDecodableRegistry`  for decoding with an identifier of type String (which is then matched with the value of the `type` field for decoding).
