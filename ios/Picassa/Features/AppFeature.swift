import Foundation
import ComposableArchitecture

struct AppFeature: Reducer {
    struct State: Equatable {
        var auth = AuthFeature.State()
        var social = SocialFeature.State()
        var chat = ChatFeature.State()
        var calendar = CalendarFeature.State()
        var profile = ProfileFeature.State()
        
        var currentUser: MyUser? = nil
    }
    
    enum Action {
        case appDidBecomeActive
        case auth(AuthFeature.Action)
        case social(SocialFeature.Action)
        case chat(ChatFeature.Action)
        case calendar(CalendarFeature.Action)
        case profile(ProfileFeature.Action)
        case userShared(MyUser)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appDidBecomeActive:
                if state.auth.isAuthenticated {
                    return .send(.profile(.onAppear))
                }
                return .none
                
            case let .auth(.authResponse(.success(user))):
                state.currentUser = user
                state.chat.currentUser = user
                return .send(.profile(.onAppear))
                
            case .profile(.logoutResponse(.success)):
                state.auth.isAuthenticated = false
                state.currentUser = nil
                return .none
                
            case let .profile(.userShared(user)):
                state.currentUser = user
                state.calendar.currentUser = user
                state.chat.currentUser = user
                return .none
                
            case let .userShared(user):
                state.currentUser = user
                state.chat.currentUser = user
                return .none
                
            case let .chat(.chatsResponse(.success(chats))):
                state.chat.chats = chats
                return .none
                
            default:
                return .none
            }
        }
        
        Scope(state: \.auth, action: /Action.auth) {
            AuthFeature()
        }
        Scope(state: \.social, action: /Action.social) {
            SocialFeature()
        }
        Scope(state: \.chat, action: /Action.chat) {
            ChatFeature()
        }
        Scope(state: \.calendar, action: /Action.calendar) {
            CalendarFeature()
        }
        Scope(state: \.profile, action: /Action.profile) {
            ProfileFeature()
        }
    }
} 
