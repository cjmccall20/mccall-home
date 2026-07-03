//
//  String+Extensions.swift
//  McCallHome
//

import Foundation

extension String {
    /// Escape LIKE/ILIKE wildcards so user input matches literally.
    /// Without this, an item named "100%" matches everything starting "100".
    var escapedForILike: String {
        self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }
}
