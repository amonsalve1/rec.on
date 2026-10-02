//
//  Pluralize.swift
//  recon
//
//  Created by Anatoli Monsalve on 10/2/2026.
//

import Foundation

extension Int {

    // MARK: - Functions

    /// Pairs the number with a noun that agrees with it: `1.counted("pick")`
    /// is "1 pick", `3.counted("pick")` is "3 picks".
    ///
    /// Counted nouns were being written as `"\(n) picks"`, which reads "1
    /// picks" whenever there is exactly one — and one is the common case for
    /// a party you started by yourself.
    ///
    /// - Parameter plural: an explicit form for nouns that do not simply take
    ///   an "s".
    func counted(_ singular: String, plural: String? = nil) -> String {
        "\(self) \(self == 1 ? singular : plural ?? singular + "s")"
    }

}
