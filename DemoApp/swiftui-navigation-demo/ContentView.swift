////
////  ContentView.swift
////  swiftui-navigation-demo
////
//
//import SmartRoutes
//import SwiftUI
//
//struct ContentView: View {
//  
//  @EnvironmentObject private var coordinator: Coordinator
//  
//  let routes: [any Destination] = [.red, .blue, .yellow]
//  
//  var body: some View {
//    VStack(spacing: 12) {
//      orizontalNavigation
//      
//      fullScreenWithNavigation
//    }
//  }
//  
//  private var orizontalNavigation: some View {
//    ForEach(routes, id: \.id) { route in
//      Button {
////        coordinator.push(route)
//        if route is BlueRoute {
//          coordinator.setRoot(.yellow)
//        } else {
//          coordinator.push(route)
//        }
//      } label: {
//        HStack {
//          Text("Push new view")
//            .tint(.primary)
//          
//          Spacer()
//          
//          Image(systemName: "arrow.right")
//            .tint(.primary)
//        }
//      }
//    }
//  }
//  
//  
//  private var fullScreenWithNavigation: some View {
//    Button {
//      coordinator.pop(.root)
////      coordinator.present(.blue, presentConfiguration: .fullScreen(navigable: true))
//    } label: {
//      HStack {
//        Text("Blue full Screen with navigation")
//          .tint(.primary)
//        
//        Spacer()
//        
//        Image(systemName: "arrow.up")
//          .tint(.primary)
//      }
//    }
//  }
//}
//
//struct RedRoute: Destination {
//  let id = UUID()
//  
//  var presentConfiguration: PresentConfiguration?
//  
//  @MainActor
//  func makeView() -> some View {
//    ContentView()
//      .background(Color.red)
//  }
//}
//
//struct BlueRoute: Destination {
//  let id = UUID()
//  
//  var presentConfiguration: PresentConfiguration? = .fullScreen(navigable: true)
//  
//  @MainActor
//  func makeView() -> some View {
//    ContentView()
//      .background(Color.blue)
//  }
//}
//
//struct YellowRoute: Destination {
//  let id = UUID()
//  
//  var presentConfiguration: PresentConfiguration?
//  
//  @MainActor
//  func makeView() -> some View {
//    ContentView()
//      .background(Color.yellow)
//  }
//}
//
//struct ContentDestination: Destination {
//  let id = UUID()
//  
//  var presentConfiguration: PresentConfiguration?
//  
//  @MainActor
//  func makeView() -> some View {
//    ContentView()
//      .background(Color.red)
//  }
//}
//
//extension Destination where Self == ContentDestination {
//  static var root: Self {
//    ContentDestination()
//  }
//}
//
//extension Destination where Self == RedRoute {
//  static var red: Self {
//    RedRoute()
//  }
//}
//
//extension Destination where Self == BlueRoute {
//  static var blue: Self {
//    BlueRoute()
//  }
//}
//
//extension Destination where Self == YellowRoute {
//  static var yellow: Self {
//    YellowRoute()
//  }
//}
//
//#Preview {
//  ContentView()
//}
