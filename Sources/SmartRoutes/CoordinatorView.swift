import SwiftUI

/// A SwiftUI `View` that uses a `Coordinator` for navigation and presentation logic.
public struct CoordinatorView<CoordinatorInterface: CoordinatorProtocol>: View {
  /// Holds the state for the coordinator.
  @ObservedObject var coordinator: CoordinatorInterface
  
  /// An optional reference to a parent coordinator.
  private var parentCoordinator: CoordinatorInterface?
  
  /// A closure that generates the content view.
  let content: () -> AnyView
  
  /// Initializes a `CoordinatorView` with a closure generating the content.
  /// - Parameter content: A closure that returns an `AnyView`.
  init(coordinator: CoordinatorInterface, content: @escaping () -> AnyView) {
    self.content = content
    self.coordinator = coordinator
  }
  
  /// Private initializer with an optional parent coordinator.
  private init(parentCoordinator: CoordinatorInterface, content: @escaping () -> AnyView) {
    self.content = content
    self.coordinator = .init(parentCoordinator: nil)
    self.parentCoordinator = parentCoordinator
  }
  
  /// The body of the `CoordinatorView`.
  public var body: some View {
    NavigationStack(path: $coordinator.path) {
      content()
        .navigationDestination(for: AnyRoute.self) {
          AnyView($0.makeView())
        }
        .sheet(item: $coordinator.sheet, content: handleModal)
//        .fullScreenCover(item: $coordinator.fullScreeCover, content: handleModal)
    }
    .environmentObject(coordinator)
    .onAppear {
      coordinator.parentCoordinator = parentCoordinator
    }
  }
  
  @ViewBuilder
  private func handleModal(route: AnyRoute) -> some View {
    switch route.presentConfiguration {
    case .fullScreen(let navigable):
      if navigable {
        CoordinatorView(parentCoordinator: coordinator) {
          AnyView(route.makeView())
        }
      } else {
        route.makeView()
      }
      
    case .sheet(let navigable, let detents):
      Group {
        if navigable {
          CoordinatorView(parentCoordinator: coordinator) {
            AnyView(
              route.makeView()
                .presentationDragIndicator(.visible)
            )
          }
        } else {
          route.makeView()
            .presentationDragIndicator(.visible)
        }
      }
      .optionalPresentationDetents(detents)
      
    default:
      EmptyView()
    }
  }
}

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
