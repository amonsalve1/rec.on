//
//  SwipeToRemove.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/31/2026.
//

import SwiftUI

/// Swipe-to-reveal a Leave button on a row that is not inside a `List`.
///
/// SwiftUI's own `.swipeActions` only works on `List` rows, and the home
/// sections are cards in a stack, so the gesture is rebuilt here. Leaving
/// takes a second tap: an accidental swipe should not drop anyone out of a
/// vote their friends are waiting on.
struct SwipeToRemove: ViewModifier {

    // MARK: - Properties

    let action: () -> Void

    @State private var offset: CGFloat = 0

    // MARK: - Constants

    private let revealWidth: CGFloat = 92
    private let openThreshold: CGFloat = 40

    // MARK: - UI

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            leaveButton

            content
                .offset(x: offset)
                .gesture(dragGesture)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: offset)
    }

    private var leaveButton: some View {
        Button {
            offset = 0
            action()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(Constants.Fonts.body)

                Text("Leave")
                    .font(Constants.Fonts.caption)
            }
            .foregroundColor(.white)
            .frame(width: revealWidth - 12)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Constants.Colors.danger.opacity(0.9))
            )
        }
        .buttonStyle(.plain)
        .opacity(offset < -8 ? 1 : 0)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard value.translation.width < 0 || offset < 0 else { return }
                offset = max(-revealWidth, min(0, value.translation.width))
            }
            .onEnded { value in
                offset = value.translation.width < -openThreshold ? -revealWidth : 0
            }
    }

}

extension View {

    /// Reveals a Leave button when the row is swiped left.
    func swipeActionsCompat(action: @escaping () -> Void) -> some View {
        modifier(SwipeToRemove(action: action))
    }

}
