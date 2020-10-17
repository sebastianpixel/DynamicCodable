# DynamicCodable

Swift Property Wrappers based on `Codable` for decoding (and encoding) types that are defined in the (JSON) data that should be decoded.

`DynamicCodable` provides a way to (de)serialize properties by wrapping them in `@DymamicEncodable`, `@DymamicDecodable` or their combination `@DynamicCodable`.

## Example: Routes
```Swift
protocol Route: TypeIdentifiable {}

struct HomeScreen: Codable {
    @DynamicCodable var `self`: Route
    @DynamicCodable var routes: [Route]
    @DynamicCodable var someRouteDict: [String: Route]

    // Optionals that are missing in the JSON (and are not replaced by `null`)
    // can't be wrapped in `@DynamicCodable`, see "Constraints".
    let someOptionalRoute: DynamicCodable<Route>?
}
```
The JSON for `HomeScreen` might look like this:
```JSON
{
    "self": {
        "type": "homescreen"
    },
    "routes": [
        {
            "type": "detailscreen",
            "id": "550121C5-3D8F-4AC8-AB14-BDF7E6D11626"
        },
        {
            "type": "detailscreen",
            "id": "697167E5-90EE-4CD2-879D-EAF49064F400"
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
`Route`s have the field `type` in common (which also is the single requirement of `TypeIdentifiable`) which identifies the actual type that should be deserialized. In order for this to work types have to be registered in `DynamicDecodableRegistry` with their respective identifier.
```Swift
DynamicDecodableRegistry.register(DetailScreenRoute.self, typeIdentifier: DetailScreenRoute.type)
DynamicDecodableRegistry.register(HomeScreenRoute.self, typeIdentifier: HomeScreenRoute.type)
DynamicDecodableRegistry.register(ProfileScreenRoute.self, typeIdentifier: ProfileScreenRoute.type)
```
To deserialize JSON like above with Swift's `Codable` alone one could define a `Route` struct that has all possible JSON fields as optional properties defined in a single place. In a modularized setup where routing targets / features like a detail screen or the home screen are separated in different modules this might not be the ideal solution. An alternative could be to not use models for routes alltogether and just deserialize dictionaries.

By using `DynamicCodable` Swift's type system can be leveraged to create clean interfaces with types that define individual optional and non-optional properties. In a possible routing setup like to following `DetailScreenRouteHandler` would have access to `DetailScreenRoute`'s `id` property without the need to unwrap an optional value and get only the information that is needed.
```Swift
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
    static let type = "detailscreen"

    let type: String
    let id: UUID
}

// Implementation module "DetailScreenImplementation"
struct DetailScreenRouteHandler: RouteHandler {
    func view(for route: DetailScreenRoute) -> Text {
        Text(route.id)
    }
}
```
## Constraints
* Types need to be identified in JSON via a field `type` which is the protocol requirement of `TypeIdentifiable`.
* Those type identifiers need to be unique. Reason is that the abstract type of the property that is about to be decoded cannot be used as "namespace" if this property is a dictionary or array as in those cases the dictionary's / array's type cannot be determined by the generic `Value` type of the property wrappers.
* Types must be registered in `DynamicDecodableRegistry` for decoding with an identifier of type String (which is then matched with the value of the `type` field for decoding).
* Optionals must not be used with a Property Wrapper but by defining the property's type e.g. as `Optional<DynamicCodable<Route>>` if the value can be missing in the JSON. This is because in automatic `Decodable` synthetization the property is not considered to be an `Optional` as the Property Wrapper itself is a non-optional value.
