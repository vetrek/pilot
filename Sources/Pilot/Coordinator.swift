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
      
    case .route(let finder):
      guard let index = finder(path.compactMap { $0.route }) else {
        print("Route not found in the path.")
        return
      }
      removeElements(from: index)
      
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
    presentConfiguration: PresentConfiguration = .sheet(navigable: false, detents: nil),
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
  
  /// Dismisses any modals (sheet or full-screen).
  public func dismiss() {
    guard let lastPresentedRouteUID else { return }
    if fullScreenCover?.id == lastPresentedRouteUID {
      dismissFullScreen()
    } else if sheet?.id == lastPresentedRouteUID {
      dismissSheet()
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
  
  /// Checks if the navigation path, sheet, or full-screen cover contains a destination of the given type.
  /// - Parameter type: The type of the destination to check for.
  /// - Returns: A boolean indicating whether a destination of the given type exists.
  public func contains<T: Destination>(_ type: T.Type) -> Bool {
    // Check if the navigation path contains a destination of the specified type.
    if path.contains(where: { $0.route is T }) {
      return true
    }
    
    // Check if the currently presented sheet is of the specified type.
    if let sheet = sheet, sheet.route is T {
      return true
    }
    
    // Check if the currently presented full-screen cover is of the specified type.
    if let fullScreenCover = fullScreenCover, fullScreenCover.route is T {
      return true
    }
    
    return false
  }
  
}

public enum PresentConfiguration: Sendable {
  case fullScreen(navigable: Bool = false)
  case sheet(navigable: Bool = false, detents: Set<PresentationDetent>? = nil)
}
