//
//  ContentView.swift
//  Picassa
//
//  Created by Milos Halecky on 03/04/2025.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        let _ = print(store)
        TabView {
            SocialView(store: store.scope(state: \.social, action: AppFeature.Action.social))
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Social")
                }
            
            ChatView(store: store.scope(state: \.chat, action: AppFeature.Action.chat))
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
            
            CalendarView(store: store.scope(state: \.calendar, action: AppFeature.Action.calendar))
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            ProfileView(store: store.scope(state: \.profile, action: AppFeature.Action.profile))
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    ContentView(
        store: Store(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
    )
}
