
//
//  ContentView.swift
//  Snippets
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipItem.createdAt, order: .reverse) private var allClips: [ClipItem]
    @Query(sort: \ClipFolder.createdAt) private var folders: [ClipFolder]
    @Query(sort: \ClipTag.name) private var tags: [ClipTag]

    @State private var searchText = ""
    @State private var selectedType: ClipType? = nil
    @State private var selectedFolder: ClipFolder? = nil
    @State private var selectedTag: ClipTag? = nil
    @State private var showingFolderManager = false
    @State private var showingTagManager = false
    @State private var selectedClip: ClipItem? = nil

    private var filteredClips: [ClipItem] {
        allClips.filter { clip in
            let matchesSearch = searchText.isEmpty ||
                clip.title.localizedCaseInsensitiveContains(searchText) ||
                clip.content.localizedCaseInsensitiveContains(searchText)

            let matchesType = selectedType == nil || clip.type == selectedType

            let matchesFolder: Bool = {
                if let folder = selectedFolder {
                    return clip.folder?.id == folder.id
                }
                return true
            }()

            let matchesTag: Bool = {
                if let tag = selectedTag {
                    return clip.tags.contains(where: { $0.id == tag.id })
                }
                return true
            }()

            return matchesSearch && matchesType && matchesFolder && matchesTag
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.blue, .green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Type filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", systemImage: "tray.full", isSelected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(ClipType.allCases, id: \.self) { type in
                            FilterChip(label: type.rawValue, systemImage: type.systemImage, isSelected: selectedType == type) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)

                // Folder filter bar
                if !folders.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All Folders", systemImage: "folder", isSelected: selectedFolder == nil) {
                                selectedFolder = nil
                            }
                            ForEach(folders) { folder in
                                FilterChip(label: folder.name, systemImage: "folder.fill", isSelected: selectedFolder?.id == folder.id) {
                                    selectedFolder = selectedFolder?.id == folder.id ? nil : folder
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                    .background(.ultraThinMaterial)
                }

                Divider()

                if filteredClips.isEmpty {
                    EmptyStateView(hasClips: !allClips.isEmpty)
                        .background(.clear)
                } else {
                    List {
                        ForEach(filteredClips) { clip in
                            ClipRowView(clip: clip)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedClip = clip
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        clip.isPinned.toggle()
                                    } label: {
                                        Label(clip.isPinned ? "Unpin" : "Pin", systemImage: clip.isPinned ? "pin.slash" : "pin")
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        modelContext.delete(clip)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.15))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                }
            }
            .navigationTitle("Snippets")
            .searchable(text: $searchText, prompt: "Search clips…")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showingFolderManager = true
                        } label: {
                            Label("Manage Folders", systemImage: "folder.badge.gear")
                        }
                        Button {
                            showingTagManager = true
                        } label: {
                            Label("Manage Tags", systemImage: "tag")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedClip) { clip in
                ClipDetailView(clip: clip, folders: folders, tags: tags)
            }
            .sheet(isPresented: $showingFolderManager) {
                FolderManagerView()
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagerView()
            }
            } // end ZStack
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Clip Row

struct ClipRowView: View {
    let clip: ClipItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: clip.type.systemImage)
                    .foregroundStyle(typeColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(clip.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if clip.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    Text(clip.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if clip.type == .image {
                    Text("Image")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(clip.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !clip.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(clip.tags) { tag in
                                Text(tag.name)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var typeColor: Color {
        switch clip.type {
        case .text:  return .blue
        case .url:   return .green
        case .image: return .purple
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let hasClips: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: hasClips ? "magnifyingglass" : "clipboard")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(hasClips ? "No matching clips" : "No clips yet")
                .font(.title3.weight(.semibold))
            Text(hasClips ? "Try adjusting your search or filters." : "Share text, links, or images from any app using the Share Sheet to save them here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ClipItem.self, ClipFolder.self, ClipTag.self], inMemory: true)
}
