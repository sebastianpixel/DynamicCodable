import DynamicCodable
import Foundation

protocol Route: DynamicCodable {
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
    let routes: [AnyCodable<Route>]
    let route: AnyCodable<Route>

    init(routes: [Route], route: Route) {
        self.routes = routes.map(AnyCodable.init)
        self.route = AnyCodable(route)
    }
}
