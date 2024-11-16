//
//  swift-navigation-routes
//

import Foundation

public enum PopDestination {
  case root
  case back
  case route(finder: ([any Route]) -> Int?)
  case index(_ index: Int)
}
