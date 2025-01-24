//
//  IconList.swift
//  IconChanger
//
//  Created by 朱浩宇 on 2022/4/27.
//

import SwiftUI
import LaunchPadManagerDBHelper

/**
 * 应用列表
 */
struct IconList: View {
    @StateObject var iconManager = IconManager.shared

    let rules = [GridItem(.adaptive(minimum: 100), alignment: .top)]

    @State var setPath: LaunchPadManagerDBHelper.AppInfo? = nil

    @State var searchText: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: rules) {
                if !searchText.isEmpty {
                    ForEach(iconManager.findSearchedImage(searchText), id: \.url) { app in
                        IconView(app: app, setPath: $setPath)
                    }
                } else {
                    ForEach(iconManager.apps, id: \.url) { app in
                        IconView(app: app, setPath: $setPath)
                    }
                }
            }
        }
        .sheet(item: $setPath) {
            ChangeView(setPath: $0)
                .onDisappear {
                    setPath = nil
                }
        }
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("Install Helper Again") {
                        try? iconManager.installHelperTool()
                    }
                } label: {
                    Image(systemName: "hammer.fill")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    iconManager.refresh()
                } label: {
                    Image(systemName: "goforward")
                }
            }
        }
    }
}

struct IconView: View {
    let app: LaunchPadManagerDBHelper.AppInfo
    @Binding var setPath: LaunchPadManagerDBHelper.AppInfo?

    var body: some View {
        VStack {
            Button {
                setPath = app
            } label: {
                Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.universalPath()))
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom)
            }
            .buttonStyle(BorderlessButtonStyle())

            Text(app.name)
                .multilineTextAlignment(.center)
        }
        // 支持拖拽图标至应用进行图标替换
        .onDrop(of: [.fileURL], delegate: MyDropDelegate(app: app))
        // 右键菜单
        .contextMenu {
            Button("Show in the Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([app.url])
            }
        }
        .padding()
    }
}

extension String: Identifiable {
    public var id: String {
        self
    }
}

struct MyDropDelegate: DropDelegate {
    let app: LaunchPadManagerDBHelper.AppInfo

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: ["public.file-url"])
    }

    func performDrop(info: DropInfo) -> Bool {
        if let item = info.itemProviders(for: ["public.file-url"]).first {
            item.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                Task {
                    if let error = error {
                        print("Failed to load dropped item: \(error.localizedDescription)")
                        return
                    }

                    if let urlData = urlData as? Data {
                        let url = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL

                        if let nsimage = NSImage(contentsOf: url) {
                            do {
                                try await IconManager.shared.setImage(nsimage, app: app)
                            } catch {
                                fatalError(error.localizedDescription)
                            }
                        }
                    }
                }
            }

            return true

        } else {
            return false
        }
    }
}
