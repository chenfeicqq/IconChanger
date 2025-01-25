//
//  IconChangerApp.swift
//  IconChanger
//
//  Created by 朱浩宇 on 2022/4/27.
//

import SwiftUI

@main
struct IconChangerApp: App {
    @StateObject var fullDiskPermision = FullDiskPermision.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 750, minHeight: 500)
                .animation(.easeInOut, value: fullDiskPermision.hasPermision)
        }
    }
}
