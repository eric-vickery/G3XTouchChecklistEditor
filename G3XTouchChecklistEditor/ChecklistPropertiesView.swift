//
//  ChecklistPropertiesView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 12/31/23.
//

import SwiftUI

struct ChecklistPropertiesView: View {
    @ObservedObject var document: ChecklistFile
    @Environment(\.undoManager) var undoManager
    @AppStorage("unlocked") var unlocked = false

    var body: some View
    {
        DisclosureGroup(isExpanded: $document.isExpanded)
        {
            VStack
            {
                HStack(spacing: 20)
                {
                    Text("Checklist Name")
                        .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    TextField("Checklist Name", text: $document.name)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .border(.secondary)
                }
                HStack(spacing: 20)
                {
                    Text("Aircraft Make and Model")
                        .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    TextField("Make and Model", text: $document.makeAndModel)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .border(.secondary)
                }
                HStack(spacing: 20)
                {
                    Text("Aircraft Information")
                        .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    TextField("Aircraft Information", text: $document.aircraftInfo)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .border(.secondary)
                }
                HStack(spacing: 20)
                {
                    Text("Manufacturer Identification")
                        .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    TextField("Manufacturer Identification", text: $document.manufacturerID)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .border(.secondary)
                }
                HStack(spacing: 20)
                {
                    Text("Copyright Information")
                        .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    TextField("Copyright", text: $document.copyright)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .border(.secondary)
                }
                HStack(spacing: 20)
                {
                    Text("Default Group")
                        .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    Text(document.getDefaultGroupName())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 20)
                {
                    Text("Default Checklist")
                        .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    Text(document.getDefaultChecklistName())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    label:
        {
            HStack
            {
                Label("Checklist File Properties", systemImage: "filemenu.and.cursorarrow")
            }
        }
        .contextMenu()
        {
            Button ()
            {
                document.addGroup(Group())
            }
        label:
            {
                Label("Add Group", systemImage: "plus.app")
                    .labelStyle(.titleAndIcon)
            }
            .disabled(!unlocked && document.groups.count >= 3)
        }
#if os(macOS)
        .onTapGesture {
            withAnimation()
            {
                document.isExpanded.toggle()
            }
        }
#endif
        .font(.title2)
    }
}

//#Preview {
//    ChecklistPropertiesView()
//}
