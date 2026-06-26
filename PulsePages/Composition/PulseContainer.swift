import Foundation

@MainActor
final class PulseContainer: ObservableObject {
    let catalog: OpenLibraryRepository
    let stackVault: StackVaultRepository
    let reachability: NetworkReachabilityMonitor

    let searchCatalog: SearchCatalogUseCase
    let fetchDossier: FetchBookDossierUseCase
    let searchAuthors: SearchAuthorsUseCase
    let browseSubject: BrowseSubjectUseCase
    let resolveISBN: ResolveISBNUseCase
    let manageStack: ManageStackUseCase

    init() {
        let repo = OpenLibraryRepository()
        catalog = repo
        stackVault = StackVaultRepository()
        reachability = NetworkReachabilityMonitor()
        searchCatalog = SearchCatalogUseCase(catalog: repo)
        fetchDossier = FetchBookDossierUseCase(catalog: repo)
        searchAuthors = SearchAuthorsUseCase(catalog: repo)
        browseSubject = BrowseSubjectUseCase(catalog: repo)
        resolveISBN = ResolveISBNUseCase(catalog: repo)
        manageStack = ManageStackUseCase(vault: stackVault)
    }
}
