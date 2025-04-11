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
    Text(#"Enter the title and press "search""#)
//      .navigationBarTitle(title)
//      .toolbar {
//        if coordinator.pagesCount > 0 {
//          ToolbarItem {
//            Button("Root") {
//              isSearchFieldFocused = false
//              coordinator.pop(.root)
//            }
//          }
//        }
//      }
      .searchable(text: $text, isPresented: $isSearchPresented)
      .onSubmit(of: .search) {
        coordinator.push(.example(title: text))
      }
      .onTapGesture {
//        coordinator.push(.example(title: "asdf"))
        coordinator.present(.example(title: "asdf"))
      }
      .focused($isSearchFieldFocused)
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
