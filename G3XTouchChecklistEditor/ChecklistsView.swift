//
//  ChecklistsView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/1/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ChecklistsView: View
{
    @ObservedObject var group: Group
    @Environment(\.undoManager) var undoManager
    @State var showChecklistEditSheet = false
    @State var selectedChecklist: Checklist = Checklist()

    var body: some View
    {
        ForEach($group.checklists)
        { $checklist in
            ChecklistView(checklist: checklist)
                .onDrag()
                {
                    selectedChecklist = checklist
                    return NSItemProvider(object: checklist.name as NSString)
                }
                .onDrop(of: [.checklist], delegate: ChecklistDropViewDelegate(destinationChecklist: checklist, group: group, draggedChecklist: selectedChecklist))
                .contextMenu()
                {
                    Button ()
                    {
                        selectedChecklist = checklist
                        showChecklistEditSheet = true
                    }
                label:
                    {
                        Label("Edit", systemImage: "pencil")
                            .labelStyle(.titleAndIcon)
                    }
                    Button()
                    {
                        group.duplicateChecklist(checklist.id)
                    }
                label:
                    {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                            .labelStyle(.titleAndIcon)
                    }
                    Button (role: .destructive)
                    {
                        group.removeChecklist(checklist)
                    }
                label:
                    {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.titleAndIcon)
                    }
                    Divider()
                    Button ()
                    {
                        group.setDefaultChecklist(checklist.id)
                    }
                label:
                    {
                        Label("Default", systemImage: (group.isDefault && checklist.isDefault) ? "checkmark.square.fill" : "checkmark.square")
                            .labelStyle(.titleAndIcon)
                    }
                    .disabled(!group.isDefault)
                    Divider()
                    Button ()
                    {
                        group.addChecklist(Checklist(), after: checklist.id)
                    }
                label:
                    {
                        Label("Add Checklist", systemImage: "plus.app")
                            .labelStyle(.titleAndIcon)
                    }
                    Button ()
                    {
                        checklist.addEntry(Entry())
                    }
                label:
                    {
                        Label("Add Item", systemImage: "plus.app")
                            .labelStyle(.titleAndIcon)
                    }
                }
        }
        .sheet(isPresented: $showChecklistEditSheet)
        {
            ChecklistEditView(checklist: selectedChecklist)
        }
    }
}

//#Preview {
//    ChecklistsView()
//}

struct ChecklistDropViewDelegate: DropDelegate
{
    let destinationChecklist: Checklist
    var group: Group
    var draggedChecklist: Checklist
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        #if os(macOS)
        if let fromIndex = group.checklists.firstIndex(of: draggedChecklist)
        {
            if let toIndex = group.checklists.firstIndex(of: destinationChecklist)
            {
                if fromIndex != toIndex
                {
                    withAnimation
                    {
                        self.group.moveChecklists(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                    }
                }
            }
        }
        #endif
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        #if os(iOS)
        if let fromIndex = group.checklists.firstIndex(of: draggedChecklist)
        {
            if let toIndex = group.checklists.firstIndex(of: destinationChecklist)
            {
                if fromIndex != toIndex
                {
                    withAnimation
                    {
                        self.group.moveChecklists(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                    }
                }
            }
        }
        #endif
    }
}
