
//
//  ClipDetailView.swift
//  Snippets
//

import SwiftUI
import SwiftData

struct ClipDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let clip: ClipItem
    let folders: [ClipFolder]
    let tags: [ClipTag]

    @State private var copied = false
    @State private var showingEditTitle = false
    @State private var editedTitle = ""
    @State private var showingFolderPicker = false
    @State private var showingTagPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Type badge
                    HStack {
                        Label(clip.type.rawValue, systemImage: clip.type.systemImage)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(typeColor.opacity(0.15))
                            .foregroundStyle(typeColor)
                            .clipShape(Capsule())
                        Spacer()
                        Text(clip.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Content preview
                    Group {
                        if clip.type == .image, let data = clip.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else if clip.type == .url {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(clip.content)
                                    .font(.body)
                                    .foregroundStyle(.blue)
                                    .underline()
                                    .textSelection(.enabled)
                            }
                        } else {
                            Text(clip.content)
                                .font(.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Folder
                    HStack {
                        Label("Folder", systemImage: "folder")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showingFolderPicker = true
                        } label: {
                            Text(clip.folder?.name ?? "None")
                                .font(.subheadline.weight(.medium))
                        }
                    }

                    Divider()

                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Tags", systemImage: "tag")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Edit") {
                                showingTagPicker = true
                            }
                            .font(.subheadline)
                        }

                        if clip.tags.isEmpty {
                            Text("No tags")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            FlowLayout(spacing: 6) {
                                ForEach(clip.tags) { tag in
                                    Text(tag.name)
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(clip.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    .tint(copied ? .green : .accentColor)
                    .animation(.easeInOut, value: copied)
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        editedTitle = clip.title
                        showingEditTitle = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button(role: .destructive) {
                        modelContext.delete(clip)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .alert("Rename Clip", isPresented: $showingEditTitle) {
                TextField("Title", text: $editedTitle)
                Button("Save") { clip.title = editedTitle }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingFolderPicker) {
                FolderPickerView(clip: clip, folders: folders)
            }
            .sheet(isPresented: $showingTagPicker) {
                TagPickerView(clip: clip, tags: tags)
            }
        }
    }

    private func copyToClipboard() {
        if clip.type == .image, let data = clip.imageData, let image = UIImage(data: data) {
            UIPasteboard.general.image = image
        } else {
            UIPasteboard.general.string = clip.content
        }
        withAnimation {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }

    private var typeColor: Color {
        switch clip.type {
        case .text:  return .blue
        case .url:   return .green
        case .image: return .purple
        }
    }
}

// MARK: - Folder Picker

struct FolderPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let clip: ClipItem
    let folders: [ClipFolder]

    var body: some View {
        NavigationStack {
            List {
                Button {
                    clip.folder = nil
                    dismiss()
                } label: {
                    HStack {
                        Label("None", systemImage: "folder.badge.minus")
                        Spacer()
                        if clip.folder == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .foregroundStyle(.primary)

                ForEach(folders) { folder in
                    Button {
                        clip.folder = folder
                        dismiss()
                    } label: {
                        HStack {
                            Label(folder.name, systemImage: "folder.fill")
                            Spacer()
                            if clip.folder?.id == folder.id {
                                Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Tag Picker

struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let clip: ClipItem
    let tags: [ClipTag]

    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    Button {
                        if clip.tags.contains(where: { $0.id == tag.id }) {
                            clip.tags.removeAll(where: { $0.id == tag.id })
                        } else {
                            clip.tags.append(tag)
                        }
                    } label: {
                        HStack {
                            Label(tag.name, systemImage: "tag.fill")
                            Spacer()
                            if clip.tags.contains(where: { $0.id == tag.id }) {
                                Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout (wrapping HStack for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
