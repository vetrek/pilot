import SwiftUI
import Pilot

@main
struct TestNavigationSearchApp: App {
  var body: some Scene {
    WindowGroup {
      CoordinatorView(root: .example(title: "Root"))
    }
  }
}

struct ExampleView: View {
  @EnvironmentObject private var coordinator: Coordinator
  
  let title: String
  
  @State private var text = ""
  @State private var isSearchPresented = true
  @FocusState private var isSearchFieldFocused: Bool
  
  var body: some View {
    VStack {
      Button("Push") {
        coordinator.push(.example(title: text))
      }

      Button("Present") {
        coordinator.present(.example(title: text))
      }
    }
  }
}

struct ExampleDestination: Destination {
  let id = UUID()
  
  var presentConfiguration: PresentConfiguration?
  
  var title: String
  
  @MainActor
  func makeView() -> some View {
    ExampleView(title: title)
  }
}

extension Destination where Self == ExampleDestination {
  static func example(title: String) -> Self {
    ExampleDestination(title: title)
  }
}
