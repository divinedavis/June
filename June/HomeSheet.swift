import MapKit
import PhotosUI
import SwiftUI

struct HomeSheet: View {
    @EnvironmentObject private var cloud: CloudKitStore
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var location: LocationManager

    @Binding var selectedItem: MKMapItem?

    @StateObject private var search = SearchSuggestionsManager()

    @State private var searchText: String = ""
    @State private var profilePickerItem: PhotosPickerItem?
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchRow
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)

            ScrollView {
                if showingSuggestions {
                    suggestionsList
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        sectionHeader("Places")
                        placesRow
                        sectionHeader("Recents")
                        recentsList
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(JuneTheme.sheetBackground)
        .onChange(of: profilePickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await cloud.saveProfile(displayName: cloud.profile.displayName ?? auth.displayName, pictureData: data)
                }
            }
        }
        .onChange(of: searchText) { newValue in
            search.update(query: newValue)
        }
        .onChange(of: location.currentLocation) { newLocation in
            if let coord = newLocation?.coordinate {
                search.region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                )
            }
        }
        .onAppear {
            if let coord = location.currentLocation?.coordinate {
                search.region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                )
            }
        }
    }

    private var showingSuggestions: Bool {
        searchText.count >= 3 && !search.suggestions.isEmpty
    }

    private var searchRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("June", text: $searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .focused($searchFocused)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        // mic action — not yet wired
                    } label: {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(Color(white: 0.18))
            )

            profileButton
        }
    }

    private var profileButton: some View {
        Menu {
            PhotosPicker(
                selection: $profilePickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Change profile picture", systemImage: "photo")
            }
            Button("Sign out", role: .destructive) {
                auth.signOut()
            }
        } label: {
            ProfileAvatar(profile: cloud.profile, fallbackInitial: auth.displayName?.first.map(String.init))
                .frame(width: 36, height: 36)
        }
    }

    // MARK: - Suggestions

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(search.suggestions.enumerated()), id: \.offset) { index, completion in
                Button {
                    Task { await pick(completion) }
                } label: {
                    SuggestionRow(completion: completion)
                }
                .buttonStyle(.plain)
                if index < search.suggestions.count - 1 {
                    Divider().background(.white.opacity(0.06))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: 0.13))
        )
    }

    private func pick(_ completion: MKLocalSearchCompletion) async {
        if let item = await search.resolve(completion) {
            await MainActor.run {
                searchFocused = false
                searchText = ""
                selectedItem = item
            }
        }
    }

    // MARK: - Default content

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var placesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(cloud.favorites) { favorite in
                    FavoriteShortcut(favorite: favorite)
                }
                AddFavoriteShortcut()
            }
            .padding(.vertical, 4)
        }
    }

    private var recentsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(cloud.recents.enumerated()), id: \.element.id) { index, place in
                RecentPlaceRow(place: place)
                if index < cloud.recents.count - 1 {
                    Divider().background(.white.opacity(0.06))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: 0.13))
        )
    }
}

private struct SuggestionRow: View {
    let completion: MKLocalSearchCompletion

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(white: 0.22)).frame(width: 36, height: 36)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(completion.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

private struct FavoriteShortcut: View {
    let favorite: Favorite

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(tint).frame(width: 64, height: 64)
                Image(systemName: favorite.kind.systemImage)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(favorite.name)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
            Text(favorite.subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 84)
    }

    private var tint: Color {
        switch favorite.kind {
        case .home: return JuneTheme.homeIcon
        case .transit: return JuneTheme.transitIcon
        case .work: return JuneTheme.workIcon
        case .custom: return JuneTheme.pinIcon
        }
    }
}

private struct AddFavoriteShortcut: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 1).frame(width: 64, height: 64)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Add")
                .font(.system(size: 15, weight: .semibold))
            Text(" ")
                .font(.system(size: 13))
        }
        .frame(width: 84)
    }
}

private struct RecentPlaceRow: View {
    let place: RecentPlace

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(white: 0.22)).frame(width: 36, height: 36)
                Image(systemName: "arrow.turn.up.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(place.origin)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct ProfileAvatar: View {
    let profile: UserProfile
    let fallbackInitial: String?

    var body: some View {
        Group {
            if let data = profile.profilePictureData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color(white: 0.25))
                    Text(fallbackInitial ?? profile.displayName?.first.map(String.init) ?? "J")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .clipShape(Circle())
        .overlay(
            Circle().stroke(.white.opacity(0.18), lineWidth: 0.5)
        )
    }
}
