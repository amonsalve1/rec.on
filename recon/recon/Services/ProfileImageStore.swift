//
//  ProfileImageStore.swift
//  recon
//
//  Created by Anatoli Monsalve on 7/29/2026.
//

import UIKit

/// Reads and writes the profile picture in the app's documents directory.
enum ProfileImageStore {

    // MARK: - Helpers

    /// Loads an image stored under the given documents-relative path, or
    /// `nil` if the file is missing or unreadable.
    static func load(from path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(path)

        guard let data = try? Data(contentsOf: url) else { return nil }

        return UIImage(data: data)
    }

    /// Writes the image as a uniquely named JPEG and returns its
    /// documents-relative filename, or `nil` if encoding or writing failed.
    static func save(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "profile_picture_\(UUID().uuidString).jpg"
        let fileURL = docs.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            return nil
        }
    }

}
