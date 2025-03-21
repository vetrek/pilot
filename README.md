
# Pilot

**Pilot** is a lightweight, type-safe, and modular navigation library for SwiftUI. It simplifies complex navigation flows while ensuring your code stays clean, reusable, and maintainable.

With **Pilot**, you can seamlessly handle navigation stacks, modals, and full-screen covers. 

---

## Key Features ✨

- **Centralized Navigation Logic**: Manage navigation stack, sheets, and full-screen modals from a single `Coordinator`.
- **Type-Safe Destinations**: Define navigation destinations using the `Destination` protocol for strongly typed and reusable routes.
- **Flexible Presentation Styles**: Support both `sheet` and `fullScreen` configurations with customizable detents.
- **Dismissal Callbacks**: Execute specific actions when navigation views are dismissed.

---

## Installation ⚙️

### Swift Package Manager

To use the Pilot library in a SwiftPM project, add the following line to the dependencies in your Package.swift file:

```
.package(url: "https://github.com/vetrek/pilot", from: "1.0.7"),
```

---

## Usage 🛠️

### 1. **Setting Up a Coordinator**

Start by creating a `Coordinator` instance and wrapping it in a `CoordinatorView`:

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
```

### 2. **Defining a Destination**

Create a custom destination by conforming to the `Destination` protocol:

```swift
import SwiftUI
import Pilot

struct LoginRoute: Destination {
  let id = UUID()
  
  @MainActor
  func makeView() -> some View {
    LoginView()
  }
}

struct LoginView: View {
  @EnvironmentObject private var coordinator: Coordinator
  
  var body: some View {
    VStack {
      Text("Welcome to Pilot!")
      Button("Next") {
        coordinator.push(.anotherRoute)
      }
    }
  }
}

extension Destination where Self == LoginRoute {
  static var login: Self {
    LoginRoute()
  }
}
```

### 3. **Navigating Between Screens**

#### Pushing a New Screen
To navigate to a new screen:

```swift
coordinator.push(.login) {
  print("Login screen dismissed")
}
```

#### Presenting a Modal
To present a sheet or full-screen modal:

```swift
coordinator.present(.login, presentConfiguration: .sheet(navigable: true)) {
  print("Sheet dismissed")
}
```

#### Dismissing Modals
Handles dismissals in navigation hierarchies:
-	Dismisses the last presented modal (sheet or full-screen cover).
-	Delegates to the parent coordinator if no modal is active.
-	Pops the navigation stack as a fallback.

```swift
coordinator.dismiss()
```

Dismisses all presented views (sheets and full-screen covers) and recursively dismisses the parent coordinator if available.

```swift
coordinator.dismissAll()
```

#### Popping the Navigation Stack
To pop to a previous screen:

```swift
coordinator.pop(.back)
```

Pop to the root:

```swift
coordinator.pop(.root)
```

---

### Custom Pop Logic

Pop to a specific route using a custom finder:

```swift
coordinator.pop(.destination(LoginRoute.self))
```

Pop to a specific index:

```swift
coordinator.pop(.index(1))
```

---

## Example App 🧑‍💻

Here’s a quick example of using **Pilot** in a real app:

```swift
import SwiftUI
import Pilot

@main
struct ExampleApp: App {
  var body: some Scene {
      WindowGroup {
         CoordinatorView(root: .login)
      }
    }
}

struct LoginRoute: Destination {
  let id = UUID()
  
  @MainActor
  func makeView() -> some View {
    LoginView()
  }
}

struct LoginView: View {
  @EnvironmentObject private var coordinator: Coordinator
  
  var body: some View {
    VStack {
      Text("Welcome to Pilot!")
      Button("Next") {
        coordinator.push(.anotherRoute)
      }
    }
  }
}

extension Destination where Self == LoginRoute {
  static var login: Self {
    LoginRoute()
  }
}

struct AnotherRoute: Destination {
  let id = UUID()
  
  @MainActor
  func makeView() -> some View {
    Text("This is another screen!")
  }
}

extension Destination where Self == AnotherRoute {
  static var anotherRoute: Self {
    AnotherRoute()
  }
}

```

---

## Contributing 🤝

Contributions are welcome! Feel free to:
- Report issues.
- Submit pull requests.
- Suggest new features.

---

## License 📜

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Support 💬

For questions or support, feel free to open an issue.
