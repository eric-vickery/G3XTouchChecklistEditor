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
            }
        }
    label:
        {
            Label("Checklist Properties", systemImage: "filemenu.and.cursorarrow")
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
