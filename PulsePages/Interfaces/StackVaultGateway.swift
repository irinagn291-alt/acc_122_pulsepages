import Foundation

@MainActor
protocol StackVaultGateway: AnyObject, ObservableObject {
    var marks: [StackMark] { get }
    func pinBook(_ book: PulseBook, note: String?, rating: Int?) -> StackPinResult
    func updateMark(workKey: String, note: String, rating: Int?)
    func removeMark(_ mark: StackMark)
    func isPinned(workKey: String) -> Bool
}
