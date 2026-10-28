import Foundation
import SwiftUI
import SwiftData

@MainActor
public final class LibraryViewModel: ObservableObject {
    @Published public var selectedSegment: LibrarySegment = .bookmarks

    public enum LibrarySegment: String, CaseIterable, Identifiable {
        case bookmarks = "Bookmarks"
        case history = "History"
        public var id: String { rawValue }
    }

    public init() {}
}
