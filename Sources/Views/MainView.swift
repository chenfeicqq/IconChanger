//
//  ContentView.swift
//  IconChanger
//
//  Created by 朱浩宇 on 2022/4/27.
//

import SwiftUI

struct MainView: View {
    @StateObject var fullDiskPermision = FullDiskPermision.shared
    @StateObject var iconManager = IconManager.shared
    @AppStorage("helperToolVersion") var helperToolVersion = 0
    
    var body: some View {
        if fullDiskPermision.hasPermision {
            AppListView()
                .task {
                    if helperToolVersion < Config.helperToolVersion {
                        if #available(macOS 13.0, *) {
                            try? await Task.sleep(until: .now + .seconds(1), clock: .suspending)
                        } else {
                            try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
                        }

                        do {
                            try iconManager.installHelperTool()
                            helperToolVersion = Config.helperToolVersion
                        } catch {
                            fatalError(error.localizedDescription)
                        }
                    }
                }
        } else {
            FullDiskAccessView(fullDiskPermision: fullDiskPermision)
                .task {
                    if #available(macOS 13.0, *) {
                        try? await Task.sleep(for: .seconds(1))
                    } else {
                        try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
                    }

                    fullDiskPermision.check()
                    if !fullDiskPermision.hasPermision {
                        NSWorkspace.shared.openLocationService(for: .fullDisk)
                    }
                }
        }
    }
}

struct FullDiskAccessView: View {
    @ObservedObject var fullDiskPermision: FullDiskPermision

    var body: some View {
        VStack {
            Text("We Need Full Disk Access")
                .font(.largeTitle.bold())
                .padding()

            VStack(alignment: .leading) {
                Text("1. Open the System Setting App")
                Text("2. Go to the security")
                Text("3. Choose the Full Disk Access")
                Text("4. Turn on the IconChanger switch")
            }
            .multilineTextAlignment(.leading)

            Button("Check the Access Permission") {
                fullDiskPermision.check()
            }
            .padding()
        }
    }
}

extension NSWorkspace {

    enum SystemServiceType: String {
        case fullDisk = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    }

    func openLocationService(for type: SystemServiceType) {
        let url = URL(string: type.rawValue)!
        NSWorkspace.shared.open(url)
    }
}
