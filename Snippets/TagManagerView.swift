
//
//  TagManagerView.swift
//  Snippets
//

import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipTag.name) private var tags: [ClipTag]

    @State private var showingAddTag = false
    @State private var newTagName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor)
                        Text(tag.name)
                        Spacer()
                        Text("\(tag.clips.count) clips")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteTags)
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newTagName = ""
                        showingAddTag = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    EditButton()
                }
            }
            .alert("New Tag", isPresented: $showingAddTag) {
                TextField("Tag name", text: $newTagName)
                Button("Create") {
                    guard !newTagName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let tag = ClipTag(name: newTagName.trimmingCharacters(in: .whitespaces))
                    modelContext.insert(tag)
                }
                Button("Cancel", role: .cancel) {}
            }
            .overlay {
                if tags.isEmpty {
                    ContentUnavailableView(
                        "No Tags",
                        systemImage: "tag.slash",
                        description: Text("Tap + to create a tag.")
                    )
                }
            }
        }
    }

    private func deleteTags(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
    }
}
