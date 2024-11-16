import SwiftUI

public protocol Route: Hashable, Identifiable, Sendable {
  associatedtype Body: View
  
  var id: UUID { get }
  
  @ViewBuilder @MainActor func makeView() -> Body
}

public extension Route {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// Type-Erased Wrapper for Route
public struct AnyRoute: Identifiable {
  public var id: UUID
  
  private let _makeView: @MainActor () -> AnyView
  private let _hash: (inout Hasher) -> Void
  private let _equals: (Any) -> Bool
  
  let route: any Route
  
  public init<R: Route>(_ route: R) {
    self.route = route
    self.id = route.id
    self._makeView = {
      AnyView(route.makeView())
    }
    self._hash = { hasher in
      route.hash(into: &hasher)
    }
    self._equals = { other in
      guard let otherRoute = other as? R else { return false }
      return route == otherRoute
    }
  }
  
  @ViewBuilder @MainActor public func makeView() -> some View {
    _makeView()
  }
}

extension AnyRoute: Equatable {
  public static func == (lhs: AnyRoute, rhs: AnyRoute) -> Bool {
    lhs._equals(rhs)
  }
}

extension AnyRoute: Hashable {
  public func hash(into hasher: inout Hasher) {
    _hash(&hasher)
  }
}
