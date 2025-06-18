import SwiftUI
import ComposableArchitecture

struct EditProfileView: View {
    let store: StoreOf<ProfileFeature>
    @State private var nickname: String
    @State private var workingHours: Double
    
    init(store: StoreOf<ProfileFeature>) {
        self.store = store
        let viewStore = ViewStore(store, observe: { $0 })
        _nickname = State(initialValue: viewStore.user?.publicUser.nickname ?? "")
        _workingHours = State(initialValue: viewStore.user?.privateUser?.lengthOfTheWorkingDay ?? 8.0)
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    TextField("Prezývka", text: $nickname)
                    
                    DurationSliderView(
                        duration: Binding(
                            get: { workingHours * 3600 },
                            set: { workingHours = $0 / 3600 }
                        )
                    )
                }
                
                Section {
                    Button("Uložiť") {
                        viewStore.send(.saveProfileTapped(nickname: nickname, workingHours: workingHours))
                    }
                    .disabled(viewStore.isLoading)
                    
                    Button("Zrušiť", role: .cancel) {
                        viewStore.send(.dismissEdit)
                    }
                }
            }
            .navigationTitle("Upraviť profil")
            .disabled(viewStore.isLoading)
        }
    }
}

struct ProfileView: View {
    let store: StoreOf<ProfileFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    if viewStore.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let user = viewStore.user {
                        HStack {
                            Text("Prezývka")
                            Spacer()
                            Text(user.publicUser.nickname ?? "")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("ID")
                            Spacer()
                            Text(user.id ?? "")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Dĺžka pracovného dňa")
                            Spacer()
                            Text("\(user.lengthOfTheWorkingDay, specifier: "%.1f") h")
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            viewStore.send(.editProfileTapped)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Upraviť profil")
                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Profil")
                } footer: {
                    if let error = viewStore.error {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        viewStore.send(.logoutTapped)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Odhlásiť sa")
                            Spacer()
                        }
                    }
                    .disabled(viewStore.isLoading)
                }
            }
            .navigationTitle("Profil")
            .sheet(isPresented: viewStore.binding(
                get: \.isEditing,
                send: { _ in .dismissEdit }
            )) {
                NavigationView {
                    EditProfileView(store: store)
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
} 
