//
//  PicassaApp.swift
//  Picassa
//
//  Created by Milos Halecky on 03/04/2025.
//

import SwiftUI
import ComposableArchitecture
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct PicassaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let store = Store(
        initialState: AppFeature.State(),
        reducer: { AppFeature() }
    )
        
    var body: some Scene {
        WindowGroup {
            WithViewStore(store, observe: { $0.auth.isAuthenticated }) { viewStore in
                if viewStore.state {
                    ContentView(store: store)
                } else {
                    AuthView(
                        store: store.scope(
                            state: \.auth,
                            action: AppFeature.Action.auth
                        )
                    )
                }
            }
            .onAppear {
                store.send(.auth(.checkAuthState))
                
                NotificationCenter.default.addObserver(
                    forName: UIApplication.didBecomeActiveNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    @MainActor func sendAction() {
                        store.send(.appDidBecomeActive)
                    }
                    Task { @MainActor in
                        sendAction()
                    }
                }
            }
        }
    }
}
