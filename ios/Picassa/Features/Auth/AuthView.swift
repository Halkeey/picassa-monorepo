import SwiftUI
import ComposableArchitecture

struct AuthView: View {
    let store: StoreOf<AuthFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(radius: 12)
                    
                    VStack(spacing: 16) {
                        TextField("Email", text: viewStore.binding(
                            get: \.email,
                            send: AuthFeature.Action.emailChanged
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        
                        SecureField("Heslo", text: viewStore.binding(
                            get: \.password,
                            send: AuthFeature.Action.passwordChanged
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if viewStore.isShowingRegister {
                            SecureField("Potvrdiť heslo", text: viewStore.binding(
                                get: \.confirmPassword,
                                send: AuthFeature.Action.confirmPasswordChanged
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    if let error = viewStore.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button {
                        if viewStore.isShowingRegister {
                            viewStore.send(.registerTapped)
                        } else {
                            viewStore.send(.loginTapped)
                        }
                    } label: {
                        if viewStore.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        } else {
                            Text(viewStore.isShowingRegister ? "Registrovať" : "Prihlásiť")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                    }
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .padding(.horizontal, 32)
                    .disabled(viewStore.isLoading)
                    
                    Button {
                        viewStore.send(.toggleRegisterView)
                    } label: {
                        Text(viewStore.isShowingRegister ? "Máte už účet? Prihláste sa" : "Nemáte účet? Zaregistrujte sa")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
} 