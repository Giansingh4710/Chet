import SwiftData
import SwiftUI

struct FavoriteShabadsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteShabad.dateViewed, order: .reverse) private var favoriteShabads: [FavoriteShabad]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if favoriteShabads.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Favorite Shabads")
                            .font(.headline)
                        Text("Start favoriting shabads to see them here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(favoriteShabads) { favoriteShabad in
                        NavigationLink(destination: ShabadViewDisplay(shabadResponse: favoriteShabad.shabad, foundByLine: favoriteShabad.selectedLine) ) {
                            FavoriteShabadRowView(favoriteShabad: favoriteShabad, modelContext: modelContext)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Favorites")
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        }
    }
}

struct FavoriteShabadRowView: View {
    let favoriteShabad: FavoriteShabad
    let modelContext: ModelContext
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(favoriteShabad.selectedLine.gurmukhi.unicode)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(favoriteShabad.selectedLine.translation.english.default)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)

                    Text(favoriteShabad.dateViewed, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text(favoriteShabad.shabad.shabadinfo.source.unicode)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)

                Text(favoriteShabad.shabad.shabadinfo.writer.english)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)

                Text("Page \(favoriteShabad.shabad.shabadinfo.pageno)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)

                Spacer()
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FavoriteShabadsView()
}
