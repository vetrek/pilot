//
//  swift-navigation-routes
//

import Foundation
import SwiftUI

struct LoginRoute: Destination {
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

extension Destination {
  static func login() -> LoginRoute {
    LoginRoute()
  }
}
