//
//  G3XTouchChecklistEditorApp.swift
//  G3XTouchChecklistEditor
//
//  Created by Eric Vickery on 12/29/23.
//

import SwiftUI

@main
struct G3XTouchChecklistEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ChecklistFile())
        { file in
            MainView(document: file.document)
#if os(macOS)
                .frame(minWidth: 800, idealWidth: 1024, maxWidth: .infinity, minHeight: 800, idealHeight: 1000, maxHeight: .infinity)
#endif
        }
#if os(macOS)
        .windowResizability(.contentSize)
#endif
        
//#if os(macOS)
//        Settings
//        {
//            GeneralSettings()
//        }
//#endif
    }
}

extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, iOS 17.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}

//struct GeneralSettings: View
//{
//    var body: some View
//    {
//        VStack {
//            Text("Hello world")
//                .padding()
//        }
//        .padding()
//        .fixedSize()
//    }
//}
