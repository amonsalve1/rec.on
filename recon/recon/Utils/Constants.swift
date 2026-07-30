//
//  Constants.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/27/2026.
//

import SwiftUI

/// App-wide design tokens. All view code resolves colors, fonts, and shared
/// spacing through this namespace instead of hardcoding literals.
enum Constants {

    /// The app color palette.
    enum Colors {

        /// Primary brand orange, used for buttons and highlights.
        static let orangePrimary = Color(red: 1.0, green: 0.55, blue: 0.35)

        /// Lighter companion orange, used in gradients and secondary accents.
        static let orangeLight = Color(red: 1.0, green: 0.75, blue: 0.4)

        /// Warm amber used in gradient midpoints.
        static let amber = Color(red: 0.99, green: 0.77, blue: 0.45)

        /// Soft peach used for subtle fills behind brand content.
        static let peach = Color(red: 1.0, green: 0.7, blue: 0.6)

        /// Top color of the side menu gradient.
        static let menuGradientTop = Color(red: 1.0, green: 0.68, blue: 0.30)

        /// Bottom color of the side menu gradient.
        static let menuGradientBottom = Color(red: 1.0, green: 0.58, blue: 0.30)

        /// Top color of the splash gradient.
        static let splashTop = Color(red: 1.0, green: 0.7, blue: 0.3)

        /// Bottom color of the splash gradient.
        static let splashBottom = Color(red: 1.0, green: 0.5, blue: 0.3)

        /// System orange used for card fills and small accents.
        static let accent = Color.orange

        /// Near-black used for primary text and dark surfaces.
        static let ink = Color(red: 0.14, green: 0.14, blue: 0.14)

        /// Neutral light background behind scrollable content.
        static let background = Color(.systemGray6)

    }

    /// The app type scale. Display faces use the rounded design.
    enum Fonts {

        /// Extra-large display, for hero numerals and splash text.
        static let display = Font.system(size: 32, weight: .bold, design: .rounded)

        /// Screen titles.
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)

        /// Section titles inside a screen.
        static let heading = Font.system(size: 24, weight: .bold)

        /// Section titles on the home screen.
        static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)

        /// Section titles outside the home screen, without the rounded face.
        static let sectionTitlePlain = Font.system(size: 22, weight: .semibold)

        /// Card titles and emphasized rows.
        static let subheading = Font.system(size: 20, weight: .semibold, design: .rounded)

        /// Titles on small cards.
        static let cardTitle = Font.system(size: 15, weight: .semibold, design: .rounded)

        /// Emphasized body text and button labels.
        static let bodySemibold = Font.system(size: 18, weight: .semibold, design: .rounded)

        /// Rounded body text in menu rows.
        static let bodyRounded = Font.system(size: 18, weight: .regular, design: .rounded)

        /// Rounded titles in list rows.
        static let rowTitle = Font.system(size: 17, weight: .regular, design: .rounded)

        /// Button labels and emphasized UI text.
        static let buttonLabel = Font.system(size: 18, weight: .semibold)

        /// Large body text, e.g. taglines and nav bar titles.
        static let bodyLarge = Font.system(size: 18)

        /// Standard body text.
        static let body = Font.system(size: 16)

        /// SF Symbol icons in menu rows.
        static let icon = Font.system(size: 22)

        /// Secondary body text.
        static let bodySmall = Font.system(size: 14)

        /// Small rounded labels under avatars and cards.
        static let label = Font.system(size: 14, weight: .regular, design: .rounded)

        /// Emphasized small rounded labels, e.g. pill buttons.
        static let labelMedium = Font.system(size: 14, weight: .medium, design: .rounded)

        /// Captions and metadata.
        static let caption = Font.system(size: 13)

        /// Dynamic subheadline for secondary rows.
        static let subheadline = Font.subheadline

        /// Emphasized dynamic subheadline for pill buttons.
        static let subheadlineSemibold = Font.subheadline.weight(.semibold)

    }

    /// Shared spacing values.
    enum Padding {

        /// Standard horizontal inset for screen content.
        static let screenHorizontal: CGFloat = 16

        /// Standard vertical rhythm between stacked sections.
        static let sectionSpacing: CGFloat = 24

    }

    /// Shared animation curves.
    enum Animations {

        /// Spring used for the side menu and other sliding chrome.
        static let menuSpring = Animation.spring(response: 0.45, dampingFraction: 0.85)

    }

}
