import Foundation

/// Data source with access to underlying sectioned model.
public protocol SectionedViewDataSourceType {
	/// Returns model at index path.
	///
	/// Throws `CombineCocoaError.itemsNotYetBound` if data not yet bound to UI.
	func model(at indexPath: IndexPath) throws -> Any
}
