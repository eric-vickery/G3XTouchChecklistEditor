//
//  ContentView.swift
//  G3XTouchChecklistEditor
//
//  Created by Eric Vickery on 12/29/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var document: ChecklistFile
    @Environment(\.undoManager) var undoManager

    var body: some View
    {
        document.undoManager = undoManager
        return VStack
        {
            ChecklistPropertiesView(document: document)
            Divider()
            ScrollView
            {
                ForEach(document.groups)
                { group in
                    GroupsView(group: group)
                }
            }
            Spacer()
        }
        .textFieldStyle(.roundedBorder)
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
    }
}

#Preview {
    ContentView(document: ChecklistFile())
}
