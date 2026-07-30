//
//  OnboardingViewModel.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import Combine
import Foundation

extension OnboardingView {

    /// The ViewModel for the intro flow shown on first launch.
    @MainActor
    class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var currentPage: Int = 0

    }

}
