
//
//  ShareViewController.swift
//  ShareExtension
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers
import SwiftData

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSharedContent()
    }

    private func loadSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }

        Task {
            var clipType: ClipType = .text
            var content = ""
            var imageData: Data? = nil
            var title = ""

            for attachment in attachments {
                // Try image first
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    if let image = try? await attachment.loadItem(forTypeIdentifier: UTType.image.identifier) as? UIImage,
                       let data = image.jpegData(compressionQuality: 0.85) {
                        clipType = .image
                        imageData = data
                        title = "Image \(Date().formatted(date: .abbreviated, time: .shortened))"
                        break
                    }
                }

                // Try URL
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await attachment.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                        clipType = .url
                        content = url.absoluteString
                        title = url.host() ?? url.absoluteString
                        break
                    }
                }

                // Try plain text
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                        clipType = .text
                        content = text
                        // Use first line as title, truncated
                        title = String(text.components(separatedBy: .newlines).first?.prefix(50) ?? text.prefix(50))
                        break
                    }
                }
            }

            await MainActor.run {
                presentShareUI(clipType: clipType, content: content, imageData: imageData, title: title)
            }
        }
    }

    private func presentShareUI(clipType: ClipType, content: String, imageData: Data?, title: String) {
        let shareView = ShareView(
            clipType: clipType,
            content: content,
            imageData: imageData,
            suggestedTitle: title,
            onSave: { [weak self] finalTitle, folder, tags in
                self?.saveClip(type: clipType, content: content, imageData: imageData, title: finalTitle, folder: folder, tags: tags)
            },
            onCancel: { [weak self] in
                self?.completeRequest()
            }
        )

        let modelContainer = makeModelContainer()
        let hostingController = UIHostingController(rootView: shareView.modelContainer(modelContainer))
        hostingController.view.backgroundColor = .systemBackground

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
    }

    private func saveClip(type: ClipType, content: String, imageData: Data?, title: String, folder: ClipFolder?, tags: [ClipTag]) {
        guard let container = try? makeModelContainer() as ModelContainer? else {
            completeRequest()
            return
        }

        let context = ModelContext(container)
        let clip = ClipItem(title: title, content: content, imageData: imageData, type: type, folder: folder)
        clip.tags = tags
        context.insert(clip)
        try? context.save()
        completeRequest()
    }

    private func makeModelContainer() -> ModelContainer {
        let schema = Schema([ClipItem.self, ClipFolder.self, ClipTag.self])
        let storeURL: URL = {
            if let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.devohn.snippets"
            ) {
                return groupURL.appendingPathComponent("Snippets.store")
            }
            return URL.documentsDirectory.appendingPathComponent("Snippets.store")
        }()
        let config = ModelConfiguration(schema: schema, url: storeURL)
        return (try? ModelContainer(for: schema, configurations: [config])) ??
               (try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]))
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
