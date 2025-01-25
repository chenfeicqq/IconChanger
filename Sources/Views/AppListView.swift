import SwiftUI
import LaunchPadManagerDBHelper

/**
 * 应用列表
 */
struct AppListView: View {
    @StateObject var iconManager = IconManager.shared

    // 定义网格布局的列配置，使用自适应布局，最小宽度为 100，顶部对齐
    let gridColumns = [GridItem(.adaptive(minimum: 100), alignment: .top)]

    // 用于存储当前选中的应用程序信息
    @State var selectedApp: LaunchPadManagerDBHelper.AppInfo? = nil

    // 用于存储搜索框中的文本
    @State var searchText: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: gridColumns) {
                if !searchText.isEmpty {
                    ForEach(iconManager.searchApps(searchText), id: \.url) { app in
                        AppView(app: app, selectedApp: $selectedApp)
                    }
                } else {
                    ForEach(iconManager.apps, id: \.url) { app in
                        AppView(app: app, selectedApp: $selectedApp)
                    }
                }
            }
        }
        // 当 selectedApp 不为空时，显示 AppChangeIconView
        .sheet(item: $selectedApp) {
            AppChangeIconView(app: $0)
                .onDisappear {
                    selectedApp = nil
                }
        }
        // 添加搜索功能，绑定 searchText 到搜索框
        .searchable(text: $searchText)
        .toolbar {
            Toolbar(iconManager: iconManager)
        }
    }
}

struct Toolbar: ToolbarContent {
    var iconManager: IconManager

    var body: some ToolbarContent {
        ToolbarItem {
            Button {
                try? iconManager.installHelperTool()
            } label: {
                // 使用 HStack 组合图标和文字
                HStack {
                    Image(systemName: "hammer.fill")
                    Text("Install Helper Again")
                }
            }
        }
        
        ToolbarItem(placement: .automatic) {
            Button {
                iconManager.refresh()
            } label: {
                HStack {
                    Image(systemName: "goforward")
                    Text("Refresh")
                }
            }
        }
    }
}

/**
 * 应用
 */
struct AppView: View {
    let app: LaunchPadManagerDBHelper.AppInfo
    @Binding var selectedApp: LaunchPadManagerDBHelper.AppInfo?

    var body: some View {
        VStack {
            Button {
                selectedApp = app
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
        .onDrop(of: [.fileURL], delegate: AppIconDropDelegate(app: app))
        // 右键菜单
        .contextMenu {
            Button("Show in the Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([app.url])
            }
        }
        .padding()
    }
}

/**
 * 拖拽替换图标
 */
struct AppIconDropDelegate: DropDelegate {
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
