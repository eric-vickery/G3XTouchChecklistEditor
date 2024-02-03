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
    @State var showChecklistEditSheet = false
    @State var selectedChecklist: Checklist = Checklist()
    @AppStorage("unlocked") var unlocked = false

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
                        checklist.removeEntries(atOffsets: indexSet)
                    }
                }
            }
            .sheet(isPresented: $showEntryEditSheet) 
            {
                EntryEditView(entry: selectedEntry)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .border(.gray)
            .frame(minHeight: minRowHeight * 20)
#if os(macOS)
            .onDeleteCommand(perform:  selection.isEmpty ? nil : { deleteSelection() })
            .copyable(checklist.entries.filter( { selection.contains($0.id) }))
            .pasteDestination(for: Entry.self) { entries in
                if !unlocked && checklist.entries.count >= 3
                {
                    return
                }
                checklist.addEntries(contentsOf: entries)
            }
            .cuttable(for: Entry.self, action:
             {
                let entries = checklist.entries.filter( { selection.contains($0.id) })
                deleteSelection()
                return entries
            })
#endif
            .contextMenu(forSelectionType: Entry.ID.self) { items in
#if os(iOS)
                if let undoManager
                {
                    Button()
                    {
                        withAnimation()
                        {
                            undoManager.undo()
                        }
                    }
                label:
                    {
                        Label("Undo \(undoManager.undoActionName)", systemImage: "arrow.uturn.backward.square")
                            .labelStyle(.titleAndIcon)
                    }
                    .disabled(!undoManager.canUndo)
                    
                    Button()
                    {
                        withAnimation()
                        {
                            undoManager.redo()
                        }
                    }
                label:
                    {
                        Label("Redo \(undoManager.redoActionName)", systemImage: "arrow.uturn.forward.square")
                            .labelStyle(.titleAndIcon)
                    }
                    .disabled(!undoManager.canRedo)
                }
#endif
                if items.isEmpty { // Empty area menu.
                    Button()
                    {
                        checklist.addEntry(Entry())
                    }
                label:
                    {
                        Label("Add Item", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
                    .disabled(!unlocked && checklist.entries.count >= 3)
                 } else if items.count == 1 { // Single item menu.
                     Button()
                     {
                         if let foundSelectedEntry = checklist.getEntry(items.first!)
                         {
                             selectedEntry = foundSelectedEntry
                             showEntryEditSheet.toggle()
                         }
                     }
                 label:
                     {
                         Label("Edit", systemImage: "pencil")
                             .labelStyle(.titleAndIcon)
                     }
                     Button()
                     {
                         checklist.duplicateEntry(items.first)
                     }
                 label:
                     {
                         Label("Duplicate", systemImage: "plus.square.on.square")
                             .labelStyle(.titleAndIcon)
                     }
                     .disabled(!unlocked && checklist.entries.count >= 3)
                     Button(role: .destructive)
                     {
                         selection = Set(items)
                         deleteSelection()
                     }
                 label:
                     {
                         Label("Delete", systemImage: "trash")
                             .labelStyle(.titleAndIcon)
                     }
                     Divider()
                     Button()
                     {
                         checklist.addEntry(Entry(), after: items.first)
                     }
                 label:
                     {
                         Label("Add Item", systemImage: "plus")
                             .labelStyle(.titleAndIcon)
                     }
                     .disabled(!unlocked && checklist.entries.count >= 3)
                 } else { // Multi-item menu.
                     Button()
                     {
                         checklist.duplicateEntries(items)
                     }
                 label:
                     {
                         Label("Duplicate", systemImage: "plus.square.on.square")
                             .labelStyle(.titleAndIcon)
                     }
                     .disabled(!unlocked && checklist.entries.count >= 3)
                     Button(role: .destructive)
                     {
                         deleteSelection()
                     }
                 label:
                     {
                         Label("Delete Selected", systemImage: "trash")
                             .labelStyle(.titleAndIcon)
                     }
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
                .onTapGesture(count: 2)
                {
                    showChecklistEditSheet.toggle()
                }
                .onTapGesture
                {
                    withAnimation()
                    {
                        checklist.isExpanded.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $showChecklistEditSheet)
        {
            ChecklistEditView(checklist: checklist)
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
    
private func deleteSelection() -> Void
    {
        checklist.removeEntries(inSet: selection)
        selection.removeAll()
    }
}


//#Preview {
//    ChecklistView()
//}
