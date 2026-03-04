
//
//  FolderManagerView.swift
//  Snippets
//

import SwiftUI
import SwiftData

struct FolderManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipFolder.createdAt) private var folders: [ClipFolder]

    @State private var showingAddFolder = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(folders) { folder in
                    HStack {
                        Label(folder.name, systemImage: "folder.fill")
                        Spacer()
                        Text("\(folder.clips.count) clips")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteFolders)
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newFolderName = ""
                        showingAddFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    EditButton()
                }
            }
            .alert("New Folder", isPresented: $showingAddFolder) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    guard !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let folder = ClipFolder(name: newFolderName.trimmingCharacters(in: .whitespaces))
                    modelContext.insert(folder)
                }
                Button("Cancel", role: .cancel) {}
            }
            .overlay {
                if folders.isEmpty {
                    ContentUnavailableView(
                        "No Folders",
                        systemImage: "folder.badge.plus",
                        description: Text("Tap + to create a folder.")
                    )
                }
            }
        }
    }

    private func deleteFolders(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(folders[index])
        }
    }
}
