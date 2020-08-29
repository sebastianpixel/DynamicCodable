import DynamicCodable
import Foundation

struct HomeScreenRoute: Route, Equatable {
    let type: String

    init() {
        self.type = Self.typeByNamingConvention
    }
}

struct DetailScreenRoute: Route, Equatable {
    let type: String
    let id: UUID

    init(id: UUID) {
        self.type = Self.typeByNamingConvention
        self.id = id
    }
}

struct OverviewScreen: Codable {
    let routes: [Route]
    let route: Route

    enum CodingKeys: String, CodingKey {
        case routes, route
    }

    init(routes: [Route], route: Route) {
        self.routes = routes
        self.route = route
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        routes = try container.decode([Route].self, forKey: .routes)
        route = try container.decode(Route.self, forKey: .route)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(routes, forKey: .routes)
        try container.encode(route, forKey: .route)
    }
}

extension OverviewScreen: Equatable {
    static func == (lhs: OverviewScreen, rhs: OverviewScreen) -> Bool {
        zip(lhs.routes, rhs.routes).allSatisfy(isEqual) && isEqual(lhs: lhs.route, rhs: rhs.route)
    }

    private static func isEqual(lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case let (lhs as DetailScreenRoute, rhs as DetailScreenRoute):
            return lhs == rhs
        case let (lhs as HomeScreenRoute, rhs as HomeScreenRoute):
            return lhs == rhs
        default:
            return false
        }
    }
}
