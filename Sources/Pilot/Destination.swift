import SwiftUI

public protocol Destination: Sendable {
  associatedtype Body: View
  
  var id: UUID { get }
  
  @ViewBuilder @MainActor func makeView() -> Body
}

public extension Destination {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// Type-Erased Wrapper for Route
public struct AnyDestination: Identifiable {
  public var id: UUID
  
  private let _makeView: @MainActor () -> AnyView
  private let _hash: (inout Hasher) -> Void
  private let _equals: (AnyDestination) -> Bool
  
  let route: any Destination
  
  public init<R: Destination>(_ route: R) {
    self.route = route
    self.id = route.id
    self._makeView = {
      AnyView(route.makeView())
    }
    self._hash = { hasher in
      route.hash(into: &hasher)
    }
    self._equals = { other in
      guard let otherRoute = other.route as? R else { return false }
      return route == otherRoute
    }
  }
  
  @ViewBuilder @MainActor public func makeView() -> AnyView {
    _makeView()
  }
}

extension AnyDestination: Equatable {
  public static func == (lhs: AnyDestination, rhs: AnyDestination) -> Bool {
    lhs._equals(rhs)
  }
}

extension AnyDestination: Hashable {
  public func hash(into hasher: inout Hasher) {
    _hash(&hasher)
  }
}
