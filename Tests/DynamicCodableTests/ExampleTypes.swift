import DynamicCodable
import Foundation

protocol Route: TypeIdentifiable {
    static var type: String { get }
}

struct HomeScreenRoute: Route, Codable, Equatable {
    static let type = "homescreen"

    let type: String

    init() {
        type = Self.type
    }
}

struct DetailScreenRoute: Route, Codable, Equatable {
    static let type = "detailscreen"

    let id: UUID
    let type: String

    init(id: UUID) {
        self.id = id
        type = Self.type
    }
}

struct UnknownRoute: Route, Codable, Equatable {
    static let type = "unknown"

    let type: String

    init() {
        type = Self.type
    }
}

struct RouteMock: Codable, Equatable {
    @DynamicCodable var route: Route

    init(route: Route) {
        _route = DynamicCodable(wrappedValue: route)
    }
}

struct OptionalRouteMock: Codable, Equatable {
    // The value in the JSON must not be missing but could be `null`.
    // This is due to the propertyWrapper not being an optional value.
    @DynamicCodable var route: Route?

    init(route: Route?) {
        _route = DynamicCodable(wrappedValue: route)
    }
}

struct OptionalRouteMockWithOptionalDynamicCodableProperty: Codable, Equatable {
    let route: DynamicCodable<Route>?

    init(route: Route?) {
        self.route = route.map(DynamicCodable.init)
    }
}

struct ArrayMock: Codable, Equatable {
    @DynamicCodable var routes: [Route]

    init(routes: [Route]) {
        _routes = DynamicCodable(wrappedValue: routes)
    }
}

struct DictionaryMock: Codable, Equatable {
    @DynamicCodable var routes: [String: Route]

    init(routes: [Route]) {
        let dict = routes.reduce(into: [String: Route]()) {
            $0[$1.type] = $1
        }
        _routes = DynamicCodable(wrappedValue: dict)
    }
}
