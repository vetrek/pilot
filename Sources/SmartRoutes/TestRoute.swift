//
//  swift-navigation-routes
//

import Foundation
import SwiftUI

struct LoginRoute: Route {
  var presentConfiguration: PresentConfiguration?
  
  let id = UUID()
  
  @MainActor
  func makeView() -> some View {
    TextView()
  }
}

struct TextView: View {
  var body: some View {
    VStack {
      Text("Hello world")
    }
  }
}

extension Route {
  static func login() -> LoginRoute {
    LoginRoute()
  }
}


