import SwiftUI
import os

/// Receives actions named by a JUN document.
///
/// Synchronous by design: a handler that needs to await something starts its own `Task`.
/// Specifying an async result model before there is anything for the renderer to do with the
/// result would be guessing.
///
/// Invoked from a SwiftUI `Button` action, so it always runs on the main thread.
public typealias JUNActionHandler = (JUNAction) -> Void

private struct JUNActionHandlerKey: EnvironmentKey {
    /// Does nothing, and says so once in debug builds.
    ///
    /// Never `print`: a library writing to standard output in a host application's release
    /// build is nobody's idea of a default.
    static let defaultValue: JUNActionHandler = { action in
        #if DEBUG
        Logger(subsystem: "com.jun.swiftui", category: "actions")
            .debug("JUN action '\(action.name, privacy: .public)' was not handled: no junActionHandler installed")
        #endif
    }
}

extension EnvironmentValues {
    var junActionHandler: JUNActionHandler {
        get { self[JUNActionHandlerKey.self] }
        set { self[JUNActionHandlerKey.self] = newValue }
    }
}

public extension View {
    /// Installs the handler that interprets actions from JUN documents rendered below this
    /// view.
    ///
    /// ```swift
    /// ComponentRenderer(component: document.root)
    ///     .junActionHandler { action in
    ///         switch action.name {
    ///         case "addToCart": cart.add(action.params["productId"]?.stringValue)
    ///         default: break
    ///         }
    ///     }
    /// ```
    ///
    /// A document can only name an action; without a handler that recognises the name,
    /// nothing happens. Action names containing a dot are reserved by the specification and
    /// are delivered here unchanged, so a future version can define standard actions without
    /// breaking this one — see ``JUNAction/isReserved``.
    func junActionHandler(_ handler: @escaping JUNActionHandler) -> some View {
        environment(\.junActionHandler, handler)
    }
}
