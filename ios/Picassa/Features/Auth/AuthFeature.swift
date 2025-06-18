import Foundation
import ComposableArchitecture
import FirebaseAuth

public struct AuthFeature: Reducer, Sendable {
    public struct State: Equatable {
        var email = ""
        var password = ""
        var isLoading = false
        var error: String?
        var isAuthenticated = false
        var currentUser: MyUser?
        var isShowingRegister = false
        var confirmPassword = ""
        
        public init() {
            // Odstránime kontrolu z init
            isAuthenticated = false
        }
    }
    
    public enum Action {
        case checkAuthState
        case emailChanged(String)
        case passwordChanged(String)
        case confirmPasswordChanged(String)
        case loginTapped
        case registerTapped
        case toggleRegisterView
        case authResponse(TaskResult<MyUser>)
    }
    
    @Dependency(\.authService) var authService
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .checkAuthState:
                // Presunieme kontrolu sem
                if let _ = Auth.auth().currentUser {
                    state.isAuthenticated = true
                }
                return .none
                
            case let .emailChanged(email):
                state.email = email
                return .none
                
            case let .passwordChanged(password):
                state.password = password
                return .none
                
            case let .confirmPasswordChanged(password):
                state.confirmPassword = password
                return .none
                
            case .loginTapped:
                state.isLoading = true
                state.error = nil
                return .run { [email = state.email, password = state.password] send in
                    await send(.authResponse(TaskResult {
                        try await authService.signIn(email: email, password: password)
                    }))
                }
                
            case .registerTapped:
                guard state.password == state.confirmPassword else {
                    state.error = "Heslá sa nezhodujú"
                    return .none
                }
                state.isLoading = true
                state.error = nil
                return .run { [email = state.email, password = state.password] send in
                    await send(.authResponse(TaskResult {
                        try await authService.register(email: email, password: password, name: email)
                    }))
                }
                
            case .toggleRegisterView:
                state.isShowingRegister.toggle()
                state.error = nil
                return .none
                
            case let .authResponse(.success(user)):
                state.isLoading = false
                state.isAuthenticated = true
                state.currentUser = user
                return .none
                
            case let .authResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
            }
        }
    }
} 
