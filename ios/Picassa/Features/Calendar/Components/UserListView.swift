import SwiftUI

struct UserListView: View {
    let users: [User]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if users.isEmpty {
                    UserRow(
                        user: User(
                            name: String(localized: "attendee.unknown"),
                            avatarUrl: nil
                        )
                    )
                } else {
                    ForEach(users, id: \.name) { user in
                        UserRow(user: user)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct UserRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 8) {
            // Avatar
            Group {
                if let url = user.avatarUrl {
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Meno
            Text(user.name)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
    }
} 