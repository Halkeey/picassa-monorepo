import Foundation
import ComposableArchitecture

struct ProfileFeature: Reducer {
    struct State: Equatable {
        var user: MyUser?
        var isLoading = false
        var error: String?
        var isEditing = false
    }
    
    enum Action {
        case onAppear
        case userResponse(TaskResult<MyUser>)
        case editProfileTapped
        case dismissEdit
        case saveProfileTapped(nickname: String, workingHours: Double)
        case saveProfileResponse(TaskResult<MyUser>)
        case logoutTapped
        case logoutResponse(TaskResult<Bool>)
        case userShared(MyUser)
    }
    
    @Dependency(\.authService) var authService
    @Dependency(\.userService) var userService
    @Dependency(\.privateUserService) var privateUserService
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let publicUser = try await userService.fetchUser(id: authService.currentUserId)
                        let privateUser = try? await privateUserService.getCurrentUserSettings(userId: authService.currentUserId)
                        let myUser = MyUser(publicUser: publicUser, privateUser: privateUser)
                        await send(.userResponse(.success(myUser)))
                    } catch {
                        await send(.userResponse(.failure(error)))
                    }
                }
                
            case let .userResponse(.success(user)):
                state.isLoading = false
                state.user = user
                return .send(.userShared(user))
                
            case let .userResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case .editProfileTapped:
                state.isEditing = true
                return .none
                
            case .dismissEdit:
                state.isEditing = false
                return .none
                
            case let .saveProfileTapped(nickname, workingHours):
                guard let userId = state.user?.id,
                      let publicUser = state.user?.publicUser else { return .none }
                
                let userName = publicUser.name
                let userAvatarUrl = publicUser.avatarUrl
                
                state.isLoading = true
                return .run { send in
                    do {
                        let updatedPublicUser = User(
                            id: userId,
                            name: userName,
                            avatarUrl: userAvatarUrl,
                            nickname: nickname
                        )
                        let savedUser = try await userService.updateUser(updatedPublicUser)
                        
                        let privateUser = PrivateUser(
                            id: userId,
                            lengthOfTheWorkingDay: workingHours
                        )
                        let savedPrivateUser = try await privateUserService.updateUserSettings(privateUser)
                        
                        let myUser = MyUser(publicUser: savedUser, privateUser: savedPrivateUser)
                        await send(.saveProfileResponse(.success(myUser)))
                    } catch {
                        await send(.saveProfileResponse(.failure(error)))
                    }
                }
                
            case let .saveProfileResponse(.success(user)):
                state.isLoading = false
                state.user = user
                state.isEditing = false
                return .send(.userShared(user)) // TODO: all userShared has to be delegated
                
            case let .saveProfileResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case .logoutTapped:
                state.isLoading = true
                return .run { send in
                    await send(.logoutResponse(TaskResult {
                        try await authService.signOut()
                        return true
                    }))
                }
                
            case .logoutResponse(.success):
                state.isLoading = false
                return .none
                
            case let .logoutResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case .userShared:
                return .none
                
            }
            
        }
    }
} 
