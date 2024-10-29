import Foundation
import SwiftUI

public protocol CoordinatorProtocol: ObservableObject {
  
  var path: [AnyRoute] { get set }
  var sheet: AnyRoute? { get set }
  var fullScreeCover: AnyRoute? { get set }
  var parentCoordinator: (any CoordinatorProtocol)? { get set }
  var pagesCount: Int { get }
  var hasPresentedView: Bool { get }
  
  init(parentCoordinator: Self?)
  
  func push(_ route: some Route, onDismiss: (() -> Void)?)
  func pop()
  func present(_ route: some Route, onDismiss: (() -> Void)?)
  func dismissSheet()
  func presentFullScreen(_ route: some Route, onDismiss: (() -> Void)?)
  func dismissFullScreen()
  func popToRoot()
  func popToHome()
  func popToPage(_ pageIndex: Int)
  func dismissModal()
  func setRoot(_ route: some Route)
}


/// `Coordinator` is a class responsible for managing the navigation and
/// presentation logic in the application.
final public class Coordinator: CoordinatorProtocol {
  
  /// Holds the current navigation path of the application.
  @Published public var path = [AnyRoute]()
  
  /// Represents the sheet (modal view) that is currently being displayed.
  @Published public var sheet: AnyRoute?
  
  /// Represents a full-screen modal cover currently being displayed.
  @Published public var fullScreeCover: AnyRoute?
  
  /// Optional reference to a parent coordinator.
  public var parentCoordinator: (any CoordinatorProtocol)?
  
  /// Initializes a new coordinator instance.
  /// - Parameter parentCoordinator: An optional parent coordinator.
  public init(parentCoordinator: Coordinator? = nil) {
    self.parentCoordinator = parentCoordinator
  }
  
  /// Holds closures that are called when navigation views are dismissed.
  private lazy var pushDismissCallbacks = [() -> Void]()
  
  /// Holds closures that are called when sheet views are dismissed.
  private lazy var sheetDismissCallbacks = [() -> Void]()
  
  /// Holds closures that are called when full-screen views are dismissed.
  private lazy var fullScreenDismissCallbacks = [() -> Void]()
  
  /// Holds closures that are called when dialog views are dismissed.
  private lazy var dialogDismissCallbacks = [() -> Void]()
  
  /// Returns the number of pages in the navigation stack.
  public var pagesCount: Int {
    path.count
  }
  
  /// Indicates whether a modal view (sheet or full-screen cover) is presented.
  public var hasPresentedView: Bool {
    sheet != nil || fullScreeCover != nil
  }
  
  /// Pushes a new page onto the navigation stack.
  /// - Parameters:
  ///   - page: The page to be pushed.
  ///   - onDismiss: A closure to be called when the page is popped.
  public func push(_ route: some Route, onDismiss: (() -> Void)? = nil) {
    //    guard !AppConfiguration.isPreview else { return }
    path.append(AnyRoute(route))
    pushDismissCallbacks.append(onDismiss ?? {})
  }
  
  /// Pops the topmost page from the navigation stack.
  public func pop() {
    if !path.isEmpty {
      path.removeLast()
    }
    let callback = pushDismissCallbacks.popLast()
    callback?()
  }
  
  /// Presents a new sheet.
  /// - Parameters:
  ///   - sheet: The sheet to be presented.
  ///   - onDismiss: A closure to be called when the sheet is dismissed.
  public func present(_ route: some Route, onDismiss: (() -> Void)? = nil) {
    var tmpSheet = route
    if tmpSheet.presentConfiguration == nil {
      tmpSheet = tmpSheet.presentConfiguration(.sheet())
    }
    self.sheet = AnyRoute(tmpSheet)
    sheetDismissCallbacks.append(onDismiss ?? {})
  }
  
  /// Dismisses the currently presented sheet.
  public func dismissSheet() {
    sheet = nil
    let callback = sheetDismissCallbacks.popLast()
    callback?()
  }
  
  /// Presents a new full-screen modal.
  /// - Parameters:
  ///   - page: The full-screen modal to be presented.
  ///   - onDismiss: A closure to be called when the modal is dismissed.
  public func presentFullScreen(_ route: some Route, onDismiss: (() -> Void)? = nil) {
    var tmpSheet = route
    if tmpSheet.presentConfiguration == nil {
      tmpSheet.presentConfiguration = .fullScreen()
    }
    self.fullScreeCover = AnyRoute(tmpSheet)
    fullScreenDismissCallbacks.append(onDismiss ?? {})
  }
  
  /// Dismisses the currently presented full-screen modal.
  public func dismissFullScreen() {
    fullScreeCover = nil
    let callback = fullScreenDismissCallbacks.popLast()
    callback?()
  }
  
  /// Pops all the pages, going back to the root of the navigation stack.
  public func popToRoot() {
    if !path.isEmpty {
      path.removeLast(path.count)
    }
  }
  
  /// Pops the pages to go back to the home page.
  public func popToHome() {
    if !path.isEmpty {
      path.removeLast(path.count - 1)
    }
  }
  
  // TODO: to improve.
  public func popTo(index finder: @escaping ([any Route]) -> Int?) {
    guard
      let index = finder(path.compactMap { $0.route }),
      index < path.count
    else {
      return
    }
    
    path.removeLast(path.count - (index + 1))
  }
  
  /// FIXME: This is a temporary solution.
  /// Pops to a specific page in the navigation stack.
  /// - Parameter pageIndex: The index of the page to pop to.
  public func popToPage(_ pageIndex: Int) {
    if !path.isEmpty {
      path.removeLast(pageIndex)
    }
  }
  
  /// Dismisses any modals (sheet or full-screen).
  public func dismissModal() {
    if fullScreeCover != nil {
      fullScreeCover = nil
      let fullScreenCallback = fullScreenDismissCallbacks.popLast()
      fullScreenCallback?()
    }
    
    if sheet != nil {
      sheet = nil
      let sheetCallback = sheetDismissCallbacks.popLast()
      sheetCallback?()
    }
    
    parentCoordinator?.dismissModal()
  }
  
  /// Sets the root page in the navigation stack.
  /// - Parameter page: The root page.
  public func setRoot(_ route: some Route) {
    path = [AnyRoute(route)]
  }
}

extension View {
  func addCoordinator() -> some View {
    modifier(CoordinatorViewModifier())
  }
}

private struct CoordinatorViewModifier: ViewModifier {
  func body(content: Content) -> some View {
    CoordinatorView(coordinator: Coordinator()) {
      AnyView(content)
    }
  }
}
