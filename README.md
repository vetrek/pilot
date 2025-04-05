# Pilot 🚀

A lightweight, type-safe navigation library for SwiftUI that makes complex navigation flows simple and maintainable.

```swift
import SwiftUI
import Pilot

@main
struct YourApp: App {
  var body: some Scene {
    WindowGroup {
      CoordinatorView(root: .login)
    }
  }
}

struct LoginView: View {
  @EnvironmentObject private var coordinator: Coordinator

  var body: some View {
    VStack {
      Text("Welcome to Pilot!")
      Button("Next") {
        coordinator.push(.dashboard)
      }
    }
  }
}
```

## Features ✨

- **Type-Safe Navigation**: Define destinations with the `Destination` protocol
- **Centralized Control**: Manage navigation from a single `Coordinator`
- **Flexible Presentation**: Support for sheets, full-screen modals, and navigation stacks
- **Clean API**: Simple methods for push, pop, present, and dismiss

## Quick Start

1. **Add Pilot** to your project:

```swift
.package(url: "https://github.com/vetrek/pilot", from: "1.0.7")
```

2. **Define a Destination**:

```swift
struct LoginRoute: Destination {
  let id = UUID()

  @MainActor
  func makeView() -> some View {
    LoginView()
  }
}
```

3. **Navigate**:

```swift
// Push a new screen
coordinator.push(.dashboard)

// Present a sheet
coordinator.present(.settings, presentConfiguration: .sheet())

// Pop back
coordinator.pop(.back)

// Dismiss modals
coordinator.dismiss()
```

## Advanced Usage

### Custom Navigation

```swift
// Pop to root
coordinator.pop(.root)

// Pop to specific screen
coordinator.pop(.destination(LoginRoute.self))

// Present with custom configuration
coordinator.present(
  .profile,
  presentConfiguration: .sheet(allowsNavigation: true, detents: [.medium])
)
```

### Nested Navigation

```swift
struct DashboardView: View {
  @EnvironmentObject private var coordinator: Coordinator

  var body: some View {
    NavigationStack {
      List {
        Button("Settings") {
          coordinator.present(.settings)
        }
        Button("Profile") {
          coordinator.push(.profile)
        }
      }
    }
  }
}
```

## Requirements

- iOS 15.0+
- macOS 12.0+
- watchOS 8.0+
- tvOS 15.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
  .package(url: "https://github.com/vetrek/pilot", from: "1.0.7")
]
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Pilot is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
