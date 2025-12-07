//
//  EditProfileView.swift
//  recon
//
//  Created by Ethan Chen on 12/5/2024.
//

import SwiftUI
import PhotosUI
import UIKit

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    let currentName: String
    let currentLocation: String
    let currentProfilePicturePath: String
    let onSave: (String, String, String) -> Void
    
    @State private var name: String
    @State private var location: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var profilePicturePath: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(currentName: String, currentLocation: String, currentProfilePicturePath: String, onSave: @escaping (String, String, String) -> Void) {
        self.currentName = currentName
        self.currentLocation = currentLocation
        self.currentProfilePicturePath = currentProfilePicturePath
        self.onSave = onSave
        _name = State(initialValue: currentName)
        _location = State(initialValue: currentLocation)
        _profilePicturePath = State(initialValue: currentProfilePicturePath)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Group {
                                if let profileImage = profileImage {
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
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.orange, lineWidth: 3)
                            )
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                    .offset(x: 40, y: 40)
                            )
                        }
                        
                        Text("Tap to change photo")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 24) {
                        Text("Edit Profile")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                            
                            TextField("Your name", text: $name)
                                .font(.system(size: 16))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .onChange(of: name) { oldValue, newValue in
                                    errorMessage = nil
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                            
                            TextField("Your location", text: $location)
                                .font(.system(size: 16))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .onChange(of: location) { oldValue, newValue in
                                    errorMessage = nil
                                }
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            if !name.isEmpty {
                                Task {
                                    await saveProfile()
                                }
                            }
                        }) {
                            Text(isLoading ? "Saving..." : "Save")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(name.isEmpty || isLoading ? Color.gray : Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    Group {
                                        if name.isEmpty || isLoading {
                                            Color.gray.opacity(0.3)
                                        } else {
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange, Color.red]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        }
                                    }
                                )
                                .cornerRadius(12)
                        }
                        .disabled(name.isEmpty || isLoading)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.14, green: 0.14, blue: 0.14))
                }
            }
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let newValue = newValue {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            profileImage = image
                            saveImageToDocuments(image: image)
                        }
                    }
                }
            }
        }
        .task {
            if !profilePicturePath.isEmpty {
                await MainActor.run {
                    profileImage = loadImage(from: profilePicturePath)
                }
            }
        }
    }
    
    @MainActor
    func loadImage(from path: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(path)
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    func saveImageToDocuments(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "profile_picture_\(UUID().uuidString).jpg"
        let fileURL = docs.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            profilePicturePath = fileName
        } catch {
        }
    }
    
    func saveProfile() async {
        await MainActor.run {
            errorMessage = nil
            isLoading = true
        }
        
        UserDefaults.standard.set(name, forKey: "userName")
        if !location.isEmpty {
            UserDefaults.standard.set(location, forKey: "userLocation")
        } else {
            UserDefaults.standard.removeObject(forKey: "userLocation")
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            isLoading = false
            onSave(name, location, profilePicturePath)
            dismiss()
        }
    }
}

