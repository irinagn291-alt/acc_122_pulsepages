import SwiftUI

struct StackJournalScreen: View {
    @EnvironmentObject private var container: PulseContainer
    @Binding var navPath: NavigationPath

    var body: some View {
        Group {
            if container.stackVault.marks.isEmpty {
                PulseEmptyState(
                    headline: "Stack is empty",
                    detail: "Pin books from any detail page to build your personal reading journal.",
                    glyph: "square.stack.3d.up"
                )
            } else {
                List {
                    ForEach(container.stackVault.marks) { mark in
                        Button {
                            navPath.append(PulseRoute.bookDetail(mark.workKey))
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(PulseTheme.pink)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mark.headline).font(.subheadline.weight(.semibold))
                                    Text(mark.byline).font(.caption).foregroundStyle(PulseTheme.muted)
                                    if let stars = mark.pulseRating {
                                        HStack(spacing: 2) {
                                            ForEach(1...stars, id: \.self) { _ in
                                                Image(systemName: "star.fill").font(.caption2).foregroundStyle(PulseTheme.mint)
                                            }
                                        }
                                    }
                                    if !mark.journalNote.isEmpty {
                                        Text(mark.journalNote).font(.caption2).foregroundStyle(PulseTheme.muted).lineLimit(2)
                                    }
                                    Text(mark.pinnedAt, style: .date).font(.caption2).foregroundStyle(PulseTheme.orchid)
                                }
                            }
                        }
                        .listRowBackground(PulseTheme.canvas)
                        .foregroundStyle(PulseTheme.ink)
                    }
                    .onDelete { idx in
                        idx.map { container.stackVault.marks[$0] }.forEach { container.manageStack.unpin($0) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Stack")
        .navigationBarTitleDisplayMode(.large)
    }
}
