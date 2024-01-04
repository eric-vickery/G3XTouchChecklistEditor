//
//  ChecklistView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/2/24.
//

import SwiftUI

struct ChecklistView: View
{
    @ObservedObject var checklist: Checklist
    @State var showEntryEditSheet = false
    @State var selectedEntry: Entry = Entry()
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    @Environment(\.undoManager) var undoManager
    @State private var selection = Set<UUID>()
    
    var body: some View
    {
        checklist.undoManager = undoManager
        return DisclosureGroup(isExpanded: $checklist.isExpanded)
        {

            List(selection: $selection)
            {
                ForEach(checklist.entries)
                { entry in
                    EntryView(entry: entry)
                        .listRowSeparator(.hidden)
#if os(iOS)
                        .listRowBackground(Color.clear)
#endif
                }
                .onMove { indexSet, offset in
                    withAnimation
                    {
                        checklist.moveEntries(fromOffsets: indexSet, toOffset: offset)
                    }
                }
                .onDelete { indexSet in
                    withAnimation
                    {
                        checklist.entries.remove(atOffsets: indexSet)
                    }
                }
            }
            .sheet(isPresented: $showEntryEditSheet) 
            {
                EntryEditView(entry: selectedEntry)
            }
#if os(iOS)
            .environment(\.editMode, $checklist.editMode)
#endif
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .border(.gray)
            .frame(minHeight: minRowHeight * 20)
#if os(macOS)
            .copyable(checklist.entries.filter( { selection.contains($0.id) }))
            .pasteDestination(for: Entry.self) { entries in
                checklist.addEntries(contentsOf: entries)
            }
            .cuttable(for: Entry.self) {
                let entries = checklist.entries.filter( { selection.contains($0.id) })
                checklist.removeEntries(inSet: selection)
                return entries
            }
#endif
            .contextMenu(forSelectionType: Entry.ID.self) { items in
                if items.isEmpty { // Empty area menu.
                     Button("New Item") { checklist.addEntry(Entry()) }

                 } else if items.count == 1 { // Single item menu.
                     Button("Edit") {
                         if let foundSelectedEntry = checklist.getEntry(items.first!)
                         {
                             selectedEntry = foundSelectedEntry
                             showEntryEditSheet.toggle()
                         }
                     }
                     Button("Copy") { }
                     Button("Delete", role: .destructive) { checklist.removeEntries(inSet: items) }

                 } else { // Multi-item menu.
                     Button("Copy") { }
                     Button("Delete Selected", role: .destructive) { checklist.removeEntries(inSet: items) }
                 }
            } primaryAction: { items in
                if items.count == 1
                {
                    if let foundSelectedEntry = checklist.getEntry(items.first!)
                    {
                        selectedEntry = foundSelectedEntry
                        showEntryEditSheet.toggle()
                    }
                }
            }
        }
    label:
        {
            HStack
            {
                Label(checklist.name, systemImage: "checklist")
                
                Spacer()
                if checklist.isExpanded
                {
                    Button()
                    {
                        checklist.addEntry(Entry())
                    }
                label:
                    {
                        Image(systemName: "plus")
                    }
                }
#if os(iOS)
                if checklist.isExpanded
                {
                    Button()
                    {
                        checklist.editMode = checklist.editMode == .active ? .inactive : .active
                    }
                label:
                    {
                        Text(checklist.editMode == .inactive ? "Edit" : "Done")
                    }
                }
#endif
            }
        }
#if os(macOS)
        .onTapGesture {
            withAnimation()
            {
                checklist.isExpanded.toggle()
            }
        }
#endif
        .font(.title2)
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
    }
}

//#Preview {
//    ChecklistView()
//}
