import SwiftUI

struct PulseRootView: View {
    @AppStorage("pulse_pages_onboarding_done") private var onboardingDone = false

    var body: some View {
        Group {
            if onboardingDone {
                PulseHubShell()
            } else {
                PulseIntroCarousel(finished: $onboardingDone)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct PulseHubShell: View {
    @EnvironmentObject private var container: PulseContainer
    @State private var activeTab: PulseTab = .feed
    @State private var navPath = NavigationPath()
    @State private var showScanner = false
    @State private var scanAlert: String?

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                PulseBackdrop()
                VStack(spacing: 0) {
                    if container.reachability.isOffline {
                        PulseOfflineBanner()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    tabContent
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .navigationDestination(for: PulseRoute.self) { route in
                switch route {
                case .searchResults(let q):
                    SearchResultsScreen(queryPhrase: q, navPath: $navPath)
                case .bookDetail(let key):
                    BookDetailScreen(workKey: key, navPath: $navPath)
                }
            }
        }
        .tint(PulseTheme.mint)
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                ISBNPulseScanner(isPresented: $showScanner) { digits in
                    Task { await handleISBN(digits) }
                }
            }
        }
        .alert("ISBN scan", isPresented: Binding(get: { scanAlert != nil }, set: { if !$0 { scanAlert = nil } })) {
            Button("OK", role: .cancel) { scanAlert = nil }
        } message: { Text(scanAlert ?? "") }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .feed:
            FeedPulseScreen(navPath: $navPath, onScanTap: { showScanner = true })
        case .stack:
            StackJournalScreen(navPath: $navPath)
        case .creators:
            CreatorsGridScreen(navPath: $navPath)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            PulsePillTab(tab: .feed, active: activeTab == .feed) {
                activeTab = .feed
                navPath = NavigationPath()
            }
            Spacer(minLength: 0)
            PulseScanFAB {
                guard !container.reachability.isOffline else { return }
                showScanner = true
            }
            .opacity(container.reachability.isOffline ? 0.4 : 1)
            Spacer(minLength: 0)
            PulsePillTab(tab: .stack, active: activeTab == .stack) {
                activeTab = .stack
                navPath = NavigationPath()
            }
            PulsePillTab(tab: .creators, active: activeTab == .creators) {
                activeTab = .creators
                navPath = NavigationPath()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            PulseTheme.surface
                .overlay(Rectangle().fill(PulseTheme.border).frame(height: 1), alignment: .top)
        )
    }

    @MainActor
    private func handleISBN(_ digits: String) async {
        do {
            let key = try await container.resolveISBN.invoke(digits)
            navPath.append(PulseRoute.bookDetail(key))
        } catch {
            scanAlert = error.localizedDescription
        }
    }
}
