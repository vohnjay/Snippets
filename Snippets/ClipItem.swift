
//
//  ClipItem.swift
//  Snippets
//

import Foundation
import SwiftData

enum ClipType: String, Codable, CaseIterable {
    case text = "Text"
    case url = "URL"
    case image = "Image"

    var systemImage: String {
        switch self {
        case .text:  return "doc.text"
        case .url:   return "link"
        case .image: return "photo"
        }
    }
}

@Model
final class ClipFolder {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \ClipItem.folder)
    var clips: [ClipItem] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

@Model
final class ClipTag {
    var name: String
    var colorHex: String

    @Relationship(deleteRule: .nullify, inverse: \ClipItem.tags)
    var clips: [ClipItem] = []

    init(name: String, colorHex: String = "#007AFF") {
        self.name = name
        self.colorHex = colorHex
    }
}

@Model
final class ClipItem {
    var id: UUID
    var title: String
    var content: String          // text content or URL string
    var imageData: Data?         // for image clips
    var clipType: String         // stores ClipType.rawValue
    var createdAt: Date
    var isPinned: Bool

    var folder: ClipFolder?
    var tags: [ClipTag] = []

    var type: ClipType {
        get { ClipType(rawValue: clipType) ?? .text }
        set { clipType = newValue.rawValue }
    }

    init(
        title: String,
        content: String,
        imageData: Data? = nil,
        type: ClipType,
        folder: ClipFolder? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.imageData = imageData
        self.clipType = type.rawValue
        self.createdAt = Date()
        self.isPinned = false
        self.folder = folder
    }
}
