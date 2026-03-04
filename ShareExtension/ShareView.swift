
//
//  ShareView.swift
//  ShareExtension
//

import SwiftUI
import SwiftData

struct ShareView: View {
    @Query(sort: \ClipFolder.createdAt) private var folders: [ClipFolder]
    @Query(sort: \ClipTag.name) private var tags: [ClipTag]

    let clipType: ClipType
    let content: String
    let imageData: Data?
    let suggestedTitle: String
    let onSave: (String, ClipFolder?, [ClipTag]) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var selectedFolder: ClipFolder? = nil
    @State private var selectedTags: [ClipTag] = []

    init(
        clipType: ClipType,
        content: String,
        imageData: Data?,
        suggestedTitle: String,
        onSave: @escaping (String, ClipFolder?, [ClipTag]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.clipType = clipType
        self.content = content
        self.imageData = imageData
        self.suggestedTitle = suggestedTitle
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: suggestedTitle)
    }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                titleSection
                folderSection
                tagsSection
            }
            .navigationTitle("Save to Snippets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title.isEmpty ? suggestedTitle : title, selectedFolder, selectedTags)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        Section("Preview") {
            if clipType == .image, let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(content)
                    .font(.body)
                    .lineLimit(4)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        Section("Title") {
            TextField("Title", text: $title)
        }
    }

    @ViewBuilder
    private var folderSection: some View {
        if !folders.isEmpty {
            Section("Folder") {
                Picker("Folder", selection: $selectedFolder) {
                    Text("None").tag(ClipFolder?.none)
                    ForEach(folders) { folder in
                        Text(folder.name).tag(Optional(folder))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if !tags.isEmpty {
            Section("Tags") {
                ForEach(tags) { tag in
                    let isSelected = selectedTags.contains(where: { $0.id == tag.id })
                    Button {
                        if isSelected {
                            selectedTags.removeAll(where: { $0.id == tag.id })
                        } else {
                            selectedTags.append(tag)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(Color.accentColor)
                            Text(tag.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
        }
    }
}
