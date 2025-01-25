//
//  ChangeView.swift
//  IconChanger
//
//  Created by 朱浩宇 on 2022/4/27.
//

import SwiftUI
import LaunchPadManagerDBHelper

struct AppChangeIconView: View {

    // 定义网格布局的列配置，使用自适应布局，最小宽度为 60，顶部对齐
    let gridColumns = [GridItem(.adaptive(minimum: 60), alignment: .top)]

    // 应用的图标资源
    @State var appIcons: [URL] = []
    // 当前选中的应用程序信息
    let app: LaunchPadManagerDBHelper.AppInfo

    @Environment(\.presentationMode) var presentationMode

    @StateObject var iconManager = IconManager.shared

    @State var importImage = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: gridColumns) {
                ForEach(appIcons, id: \.self) { icon in
                    ImageView(url: icon, app: app)
                }

                Spacer()
            }
        }
        .fileImporter(isPresented: $importImage, allowedContentTypes: [.image, .icns]) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    if let nsimage = NSImage(contentsOf: url) {
                        do {
                            try IconManager.shared.setImage(nsimage, app: app)
                        } catch {
                            fatalError(error.localizedDescription)
                        }
                    }
                    url.stopAccessingSecurityScopedResource()
                    presentationMode.wrappedValue.dismiss()
                }
            case .failure(let error):
                print(error)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }

            ToolbarItem(placement: .automatic) {
                Button("Choose from the Local") {
                    importImage.toggle()
                }
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            appIcons = iconManager.getIconInPath(app.url)
        }
    }
}

/**
 * 图片
 */
struct ImageView: View {
    let url: URL
    let app: LaunchPadManagerDBHelper.AppInfo

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        
        let nsimage = NSImage(byReferencing: url)
        
        Image(nsImage: nsimage)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 60, maxHeight: 60)
            .aspectRatio(contentMode: .fit)
            .onTapGesture {
                do {
                    try IconManager.shared.setImage(nsimage, app: app)
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    print(error)
                }
            }
    }
}
