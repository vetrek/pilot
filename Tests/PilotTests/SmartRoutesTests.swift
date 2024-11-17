import Testing
@testable import Pilot
import XCTest
import SwiftUI

final class CoordinatorTests: XCTestCase {
  
  @MainActor func testInitWithRootDestination() {
    let rootDestination = MockDestination()
    let coordinator = Coordinator(root: rootDestination)
    
    XCTAssertEqual(coordinator.root.id, AnyDestination(rootDestination).id)
    XCTAssertEqual(coordinator.pagesCount, 0)
    XCTAssertNil(coordinator.parentCoordinator)
  }
  
  @MainActor func testPushAndPop() {
    let rootDestination = MockDestination()
    let coordinator = Coordinator(root: rootDestination)
    let newDestination = MockDestination()
    
    coordinator.push(newDestination)
    XCTAssertEqual(coordinator.pagesCount, 1)
    XCTAssertEqual(coordinator.path.last?.id, AnyDestination(newDestination).id)
    
    coordinator.pop(.back)
    XCTAssertEqual(coordinator.pagesCount, 0)
  }
  
  @MainActor func testPopToRoot() {
    let rootDestination = MockDestination()
    let coordinator = Coordinator(root: rootDestination)
    
    coordinator.push(MockDestination())
    coordinator.push(MockDestination())
    
    XCTAssertEqual(coordinator.pagesCount, 2)
    
    coordinator.pop(.root)
    XCTAssertEqual(coordinator.pagesCount, 0)
  }
  
  @MainActor func testPresentSheet() {
    let rootDestination = MockDestination()
    let coordinator = Coordinator(root: rootDestination)
    let sheetDestination = MockDestination()
    
    coordinator.present(sheetDestination, presentConfiguration: .sheet()) {
      print("Sheet dismissed")
    }
    
    XCTAssertEqual(coordinator.sheet?.id, AnyDestination(sheetDestination).id)
    XCTAssertTrue(coordinator.hasPresentedView)
    
    coordinator.dismiss()
    XCTAssertNil(coordinator.sheet)
    XCTAssertFalse(coordinator.hasPresentedView)
  }
  
  @MainActor func testPresentFullScreenCover() {
    let rootDestination = MockDestination()
    let coordinator = Coordinator(root: rootDestination)
    let coverDestination = MockDestination()
    
    coordinator.present(coverDestination, presentConfiguration: .fullScreen()) {
      print("Full-screen dismissed")
    }
    
    XCTAssertEqual(coordinator.fullScreenCover?.id, AnyDestination(coverDestination).id)
    XCTAssertTrue(coordinator.hasPresentedView)
    
    coordinator.dismiss()
    XCTAssertNil(coordinator.fullScreenCover)
    XCTAssertFalse(coordinator.hasPresentedView)
  }
  
  @MainActor func testDismissAll() {
    let rootDestination = MockDestination()
    let parentCoordinator = Coordinator(root: rootDestination)
    let childCoordinator = Coordinator(parentCoordinator: parentCoordinator, root: MockDestination())
    
    childCoordinator.present(MockDestination(), presentConfiguration: .sheet())
    childCoordinator.present(MockDestination(), presentConfiguration: .fullScreen())
    
    childCoordinator.dismissAll()
    
    XCTAssertNil(childCoordinator.sheet)
    XCTAssertNil(childCoordinator.fullScreenCover)
    XCTAssertNil(parentCoordinator.sheet)
    XCTAssertNil(parentCoordinator.fullScreenCover)
  }
  
  @MainActor func testSetRootAndPopAll() {
    let rootDestination = MockDestination()
    let newRoot = MockDestination()
    let coordinator = Coordinator(root: rootDestination)
    
    coordinator.push(MockDestination())
    XCTAssertEqual(coordinator.pagesCount, 1)
    
    coordinator.setRoot(newRoot, popAll: true)
    XCTAssertEqual(coordinator.root.id, AnyDestination(newRoot).id)
    XCTAssertEqual(coordinator.pagesCount, 0)
  }
}

// Mock Destination class conforming to `Destination`
struct MockDestination: Destination {
  let id = UUID()
  
  var presentConfiguration: PresentConfiguration?
  
  @MainActor
  func makeView() -> some View {
    TextView()
  }
}

extension Destination where Self == MockDestination {
  static var root: Self {
    MockDestination()
  }
}

struct TextView: View {
  var body: some View {
    VStack {
      Text("Hello world")
    }
  }
}
