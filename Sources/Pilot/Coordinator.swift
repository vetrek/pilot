import Foundation
import SwiftUI

/// `Coordinator` is a class responsible for managing the navigation and presentation logic in the application.
@MainActor
final public class Coordinator: ObservableObject {
  
  /// Holds the root destination of the application.
  @Published var root: AnyDestination
  
  /// Holds the current navigation path of the application.
  @Published var path = [AnyDestination]()
  
  /// Represents the sheet (modal view) that is currently being displayed.
  @Published var sheet: AnyDestination?
  
  /// Represents a full-screen modal cover currently being displayed. 
  @Published var fullScreenCover: AnyDestination?
  
  /// Track the lastly presented Route
  private var lastPresentedRouteUID: UUID?
  
  /// Optional reference to a parent coordinator.
  public internal(set) weak var parentCoordinator: Coordinator?
  
  /// Holds closures that are called when navigation views are dismissed.
  private var pushDismissCallbacks = [() -> Void]()
  
  /// Holds closures that are called when sheet views are dismissed.
  private var sheetDismissCallbacks = [() -> Void]()
  
  /// Holds closures that are called when full-screen views are dismissed.
  private var fullScreenDismissCallbacks = [() -> Void]()
  
  /// Stores configuration for presented routes.
  lazy var presentConfigurations = [AnyDestination: PresentConfiguration]()
  
  /// Initializes the coordinator with a root destination.
  /// - Parameter root: The initial root destination.
  public init(root: any Destination) {
    self.root = AnyDestination(root)
  }
  
  /// Initializes a new coordinator with an optional parent and root destination.
  /// - Parameters:
  ///   - parentCoordinator: Optional parent coordinator.
  ///   - root: The initial root destination.
  init(parentCoordinator: Coordinator? = nil, root: any Destination) {
    self.parentCoordinator = parentCoordinator
    self.root = AnyDestination(root)
  }
  
  /// Returns the number of pages in the navigation stack.
  public var pagesCount: Int {
    path.count
  }
  
  /// Indicates whether a modal view (sheet or full-screen cover) is presented.
  public var hasPresentedView: Bool {
    sheet != nil || fullScreenCover != nil
  }
  
  /// Indicates whether the current coordinator is presented.
  public var isPresented: Bool {
    parentCoordinator?.hasPresentedView == true
  }
  
  // MARK: - Push and Pop functions
  
  /// Pushes a new page onto the navigation stack.
  /// - Parameters:
  ///   - page: The page to be pushed.
  ///   - onDismiss: A closure to be called when the page is popped.
  public func push(_ route: some Destination, onDismiss: (() -> Void)? = nil) {
    path.append(AnyDestination(route))
    pushDismissCallbacks.append(onDismiss ?? {})
  }
  
  /// Pops pages from the navigation stack based on the specified `Pop` type.
  /// - Parameter popType: The type of pop action, which could be to root, a specific route, or an index.
  public func pop(_ destination: PopDestination = .back) {
    guard !path.isEmpty else {
      return
    }
    
    switch destination {
    case .root:
      // Clear the navigation path entirely as we rely on the root reference
      path = []
      pushDismissCallbacks.removeAll()
      
    case .back:
      let targetIndex = max(path.count - 2, 0)
      guard targetIndex > 0 else {
        pop(.root)
        return
      }
      
      removeElements(from: targetIndex)
      
    case .destination(let destination):
      if let targetIndex = path.firstIndex(where: { anyRoute in
        type(of: anyRoute.route) == destination
      }) {
        removeElements(from: targetIndex)
      } else {
        print("Destination of type \(destination) not found in the path.")
      }
      
    case .index(let index):
      guard index >= 0 && index < path.count else {
        print("Index out of bounds for index-based pop.")
        return
      }
      guard index > 0 else {
        pop(.root)
        return
      }
      
      removeElements(from: index)
    }
  }
  
  /// Helper function to remove elements from the path and invoke their dismissal callbacks.
  /// - Parameter targetIndex: The index to retain up to, removing the rest.
  private func removeElements(from targetIndex: Int) {
    let elementsToRemove = path.count - targetIndex - 1
    
    guard elementsToRemove > 0 else { return }
    
    let callbacksToInvoke = pushDismissCallbacks.suffix(elementsToRemove)
    pushDismissCallbacks.removeLast(elementsToRemove)
    path.removeLast(elementsToRemove)
    
    callbacksToInvoke.forEach { $0() }
  }
  
  // MARK: - Present and Dismiss functions
  
  /// Presents a new sheet.
  /// - Parameters:
  ///   - sheet: The sheet to be presented.
  ///   - onDismiss: A closure to be called when the sheet is dismissed.
  public func present(
    _ route: some Destination,
    presentConfiguration: PresentConfiguration = .sheet(allowsNavigation: false, detents: nil),
    onDismiss: (() -> Void)? = nil
  ) {
    let anyRoute = AnyDestination(route)
    presentConfigurations[anyRoute] = presentConfiguration
    lastPresentedRouteUID = anyRoute.id
    
    switch presentConfiguration {
    case .fullScreen:
      fullScreenCover = anyRoute
      fullScreenDismissCallbacks.append(onDismiss ?? {})
    case .sheet:
      sheet = anyRoute
      sheetDismissCallbacks.append(onDismiss ?? {})
    }
  }
  
  /// Dismisses the currently presented sheet.
  private func dismissSheet() {
    sheet = nil
    let callback = sheetDismissCallbacks.popLast()
    callback?()
    // Set the last presented route uid to the sheet if present
    lastPresentedRouteUID = fullScreenCover?.id
  }
  
  /// Dismisses the currently presented full-screen modal.
  private func dismissFullScreen() {
    fullScreenCover = nil
    let callback = fullScreenDismissCallbacks.popLast()
    callback?()
    // Set the last presented route uid to the fullscreen route if present
    lastPresentedRouteUID = sheet?.id
  }
  
  /// Dismisses the currently presented modal (sheet or full-screen cover).
  ///
  /// - If a modal is presented, it dismisses the last presented modal view.
  /// - If no modal is found, it delegates the dismissal to the parent coordinator.
  /// - If no parent coordinator exists, it pops the current navigation stack.
  ///
  /// This method ensures proper dismissal in hierarchical navigation structures.
  public func dismiss() {
    if let lastPresentedRouteUID {
      if fullScreenCover?.id == lastPresentedRouteUID {
        dismissFullScreen()
      } else if sheet?.id == lastPresentedRouteUID {
        dismissSheet()
      }
    } else if let parentCoordinator {
      parentCoordinator.dismiss()
    } else {
      pop()
    }
  }
  
  /// Dismisses all presented views (sheets and full-screen covers)
  /// and recursively dismisses in the parent coordinator if available.
  public func dismissAll() {
    if fullScreenCover != nil {
      dismissFullScreen()
    }
    if sheet != nil {
      dismissSheet()
    }
    parentCoordinator?.dismissAll()
  }
  
  /// Updates the root destination and optionally clears the navigation stack.
  /// - Parameters:
  ///   - root: The new root destination.
  ///   - popAll: Whether to clear the stack.
  public func setRoot(_ root: any Destination, popAll: Bool = false) {
    self.root = AnyDestination(root)
    if popAll {
      pop(.root)
    }
  }
  
  /// Checks if the navigation path contains a destination of the given type.
  /// - Parameter type: The type of the destination to check for.
  /// - Returns: A boolean indicating whether a destination of the given type exists.
  public func contains<T: Destination>(_ type: T.Type) -> Bool {
    path.contains(where: { $0.route is T })
  }
  
  /// Checks whether a specific destination is currently being presented as a modal (sheet or full-screen cover).
  ///
  /// - Parameter destination: The destination to check for presentation.
  /// - Returns: `true` if the specified destination is currently being presented, either as a sheet or full-screen cover; `false` otherwise.
  ///
  /// This function is useful for determining if a particular modal is active, which can help in coordinating navigation logic
  /// or avoiding duplicate presentations of the same modal.
  public func isPresenting<T: Destination>(_ type: T.Type) -> Bool {
    sheet?.route is T || fullScreenCover?.route is T
  }
  
  /// Determines whether a modal view of a specific type is currently being presented.
  ///
  /// This function checks both sheet and full-screen cover presentations to see if either
  /// matches the specified `View` type.
  ///
  /// - Parameter type: The `View` type to check for presentation.
  /// - Returns: `true` if a modal view (sheet or full-screen cover) of the specified type is currently presented; `false` otherwise.
  ///
  /// This is useful for ensuring that a specific modal is active or avoiding duplicate presentations of the same view type.
  public func isViewPresented<V: View>(_ type: V.Type) -> Bool {
    if let sheet, sheet.makeView() is V {
      true
    } else if let fullScreenCover, fullScreenCover.makeView() is V {
      true
    } else if let parentCoordinator {
      parentCoordinator.isViewPresented(type)
    } else {
      false
    }
  }
}

/// `PresentConfiguration` defines the configuration for presenting modal views in the application.
///
/// This enum supports two types of modal presentations:
/// - `fullScreen`: Displays a full-screen modal, with an optional `allowsNavigation` flag
///   to determine if the modal should support a nested navigation stack.
/// - `sheet`: Displays a modal sheet, with options for `allowsNavigation` and
///   `detents` to configure the sheet's behavior and appearance.
///
/// ### `allowsNavigation`
/// The `allowsNavigation` flag determines whether the presented modal will have its own
/// independent navigation stack:
/// - **`true`**: The modal view is wrapped in its own `CoordinatorView`, meaning it can
///   manage its own navigation (e.g., push and pop views) without affecting the main
///   application's navigation stack.
/// - **`false`**: The modal presents a single view without its own navigation stack,
///   ideal for simpler use cases like forms or alerts.
///
/// Use these configurations when presenting views modally to specify the desired presentation style
/// and behavior.
public enum PresentConfiguration: Sendable {
  case fullScreen(allowsNavigation: Bool = false)
  case sheet(allowsNavigation: Bool = false, detents: Set<PresentationDetent>? = nil)
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

/// A SwiftUI `View` that uses a `Coordinator` for navigation and presentation logic.
public struct CoordinatorView: View {
  /// Holds the state for the coordinator.
  @ObservedObject var coordinator: Coordinator
  
  /// An optional reference to a parent coordinator.
  private var parentCoordinator: Coordinator?
  
  /// Initializes a `CoordinatorView` with a closure generating the content.
  /// - Parameter content: A closure that returns an `AnyView`.
  public init(root: any Destination) {
    self.coordinator = Coordinator(root: root)
  }
  
  /// Private initializer with an optional parent coordinator.
  private init(parentCoordinator: Coordinator, root: any Destination) {
    self.init(root: root)
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
    case .fullScreen(let allowsNavigation):
      if allowsNavigation {
        CoordinatorView(parentCoordinator: coordinator, root: route.route)
      } else {
        route.makeView()
      }
      
    case .sheet(let allowsNavigation, let detents):
      Group {
        if allowsNavigation {
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
