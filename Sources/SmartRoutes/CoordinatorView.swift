import SwiftUI

private struct OptionalPresentationDetentsModifier: ViewModifier {
  var detents: Set<PresentationDetent>?
  
  func body(content: Content) -> some View {
    if let detents = detents {
      return AnyView(content.presentationDetents(detents))
    } else {
      return AnyView(content)
    }
  }
}

private extension View {
  func optionalPresentationDetents(_ detents: Set<PresentationDetent>?) -> some View {
    self.modifier(OptionalPresentationDetentsModifier(detents: detents))
  }
}

/// A SwiftUI `View` that uses a `Coordinator` for navigation and presentation logic.
public struct CoordinatorView: View {
  /// Holds the state for the coordinator.
  @ObservedObject var coordinator: Coordinator
  
  /// An optional reference to a parent coordinator.
  private var parentCoordinator: Coordinator?
  
  /// Initializes a `CoordinatorView` with a closure generating the content.
  /// - Parameter content: A closure that returns an `AnyView`.
  public init(coordinator: Coordinator) {
    self.coordinator = coordinator
  }
  
  /// Private initializer with an optional parent coordinator.
  private init(parentCoordinator: Coordinator, root: any Destination) {
    self.init(coordinator: .init(parentCoordinator: nil, root: root))
    self.parentCoordinator = parentCoordinator
  }
  
  /// The body of the `CoordinatorView`.
  public var body: some View {
    NavigationStack(path: $coordinator.path) {
      coordinator.root.makeView()
        .navigationDestination(for: AnyDestination.self) {
          $0.makeView()
        }
        .sheet(item: $coordinator.sheet, content: handleModal)
        .fullScreenCover(item: $coordinator.fullScreenCover, content: handleModal)
    }
    .environmentObject(coordinator)
    .onAppear {
      coordinator.parentCoordinator = parentCoordinator
    }
  }
  
  @ViewBuilder
  private func handleModal(route: AnyDestination) -> some View {
    switch coordinator.presentConfigurations[route] {
    case .fullScreen(let navigable):
      if navigable {
        CoordinatorView(parentCoordinator: coordinator, root: route.route)
      } else {
        route.makeView()
      }
      
    case .sheet(let navigable, let detents):
      Group {
        if navigable {
          CoordinatorView(parentCoordinator: coordinator, root: route.route)
        } else {
          route.makeView()
        }
      }
      .presentationDragIndicator(.visible)
      .optionalPresentationDetents(detents)
      
    default:
      EmptyView()
    }
  }
}
