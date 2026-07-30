//
//  EditProfileView.swift
//  recon
//
//  Created by Ethan Chen on 12/5/2024.
//

import PhotosUI
import SwiftUI
import UIKit

/// The sheet for editing the user's name, location, and profile picture.
struct EditProfileView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ViewModel

    let onSave: (String, String, String) -> Void

    // MARK: - Constants

    private let avatarSize: CGFloat = 120

    // MARK: - Init

    init(
        currentName: String,
        currentLocation: String,
        currentProfilePicturePath: String,
        onSave: @escaping (String, String, String) -> Void
    ) {
        self.onSave = onSave
        _viewModel = StateObject(
            wrappedValue: ViewModel(
                name: currentName,
                location: currentLocation,
                picturePath: currentProfilePicturePath
            )
        )
    }

    // MARK: - UI

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    photoSection

                    formSection

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.ink)
                }
            }
        }
        .onChange(of: viewModel.selectedPhoto) { _, newValue in
            Task {
                await viewModel.handlePhotoSelection(newValue)
            }
        }
        .task {
            viewModel.loadExistingImage()
        }
    }

    private var photoSection: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                avatar
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Constants.Colors.accent, lineWidth: 3)
                    )
                    .overlay(cameraBadge)
            }

            Text("Tap to change photo")
                .font(Constants.Fonts.bodySmall)
                .foregroundColor(.gray)
        }
        .padding(.top, 40)
    }

    @ViewBuilder
    private var avatar: some View {
        if let profileImage = viewModel.profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .foregroundColor(.gray)
        }
    }

    private var cameraBadge: some View {
        Image(systemName: "camera.fill")
            .font(Constants.Fonts.iconLarge)
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Constants.Colors.accent)
            .clipShape(Circle())
            .offset(x: 40, y: 40)
    }

    private var formSection: some View {
        VStack(spacing: 24) {
            Text("Edit Profile")
                .font(Constants.Fonts.headingMedium)
                .foregroundColor(Constants.Colors.ink)
                .multilineTextAlignment(.center)

            field(
                label: "Name",
                placeholder: "Your name",
                text: $viewModel.name
            )

            field(
                label: "Location",
                placeholder: "Your location",
                text: $viewModel.location
            )

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Constants.Fonts.bodySmall)
                    .foregroundColor(Constants.Colors.danger)
                    .padding(.horizontal)
            }

            saveButton
        }
        .padding(.horizontal, 32)
    }

    private var saveButton: some View {
        Button {
            guard viewModel.canSave else { return }
            Task {
                await viewModel.save()
                onSave(
                    viewModel.name,
                    viewModel.location,
                    viewModel.profilePicturePath
                )
                dismiss()
            }
        } label: {
            Text(viewModel.isLoading ? "Saving..." : "Save")
                .font(Constants.Fonts.buttonLabel)
                .foregroundColor(viewModel.canSave ? .white : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(saveButtonBackground)
                .cornerRadius(12)
        }
        .disabled(!viewModel.canSave)
    }

    @ViewBuilder
    private var saveButtonBackground: some View {
        if viewModel.canSave {
            LinearGradient(
                gradient: Gradient(colors: [
                    Constants.Colors.accent,
                    Constants.Colors.danger
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            Color.gray.opacity(0.3)
        }
    }

    // MARK: - Supporting

    private func field(
        label: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Constants.Fonts.fieldLabel)
                .foregroundColor(Constants.Colors.ink)

            TextField(placeholder, text: text)
                .font(Constants.Fonts.body)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .onChange(of: text.wrappedValue) { _, _ in
                    viewModel.errorMessage = nil
                }
        }
    }

}

#Preview {
    EditProfileView(
        currentName: "Anatoli",
        currentLocation: "Ithaca, NY",
        currentProfilePicturePath: "",
        onSave: { _, _, _ in }
    )
}
