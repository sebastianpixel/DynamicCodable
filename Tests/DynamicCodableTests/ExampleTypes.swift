import DynamicCodable
import Foundation

protocol Route: DynamicCodableProtocol {
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

struct HomeScreen: Codable, Equatable {
    let routes: [DynamicCodable<Route>]
    @DynamicCodable var route: Route

    init(routes: [Route], route: Route) {
        self.routes = routes.map(DynamicCodable.init)
        _route = DynamicCodable(wrappedValue: route)
    }
}
