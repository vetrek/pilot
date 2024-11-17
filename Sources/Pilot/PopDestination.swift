//
//  swift-navigation-routes
//

import Foundation

public enum PopDestination {
  case root
  case back
  case destination(_ destination: any Destination.Type)
  case index(_ index: Int)
}
