//
//  ContentView.swift
//  G3XTouchChecklistEditor
//
//  Created by Eric Vickery on 12/29/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var document: ChecklistFile
    @Environment(\.undoManager) var undoManager
    @State var showGroupEditSheet = false
    @State var selectedGroup: Group = Group()

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
                    .onDrag()
                    {
                        selectedGroup = group
                        return NSItemProvider(object: group.name as NSString)
                    }
                    .onDrop(of: [.checklistGroup], delegate: DropViewDelegate(destinationGroup: group, groups: $document.groups, draggedGroup: $selectedGroup))
                    .contextMenu()
                    {
                        Button ()
                        {
                            selectedGroup = group
                            showGroupEditSheet = true
                        }
                    label:
                        {
                            Label("Edit", systemImage: "pencil")
                                .labelStyle(.titleAndIcon)
                        }
                        Button (role: .destructive)
                        {
                            document.removeGroup(group)
                        }
                    label:
                        {
                            Label("Delete", systemImage: "trash")
                                .labelStyle(.titleAndIcon)
                        }
                        Divider()
                        Button ()
                        {
                            document.addGroup(Group())
                        }
                    label:
                        {
                            Label("Add Group", systemImage: "plus.app")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        .sheet(isPresented: $showGroupEditSheet)
        {
            GroupEditView(group: selectedGroup)
        }
    }
}

#Preview {
    ContentView(document: ChecklistFile())
}

struct DropViewDelegate: DropDelegate
{
    let destinationGroup: Group
    @Binding var groups: [Group]
    @Binding var draggedGroup: Group
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        print("In performDrop")
        #if os(macOS)
        if let fromIndex = groups.firstIndex(of: draggedGroup)
        {
            if let toIndex = groups.firstIndex(of: destinationGroup)
            {
                if fromIndex != toIndex
                {
                    withAnimation
                    {
                        self.groups.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                    }
                }
            }
        }
        #endif
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        print("In dropEntered")
        #if os(iOS)
        if let fromIndex = groups.firstIndex(of: draggedGroup)
        {
            if let toIndex = groups.firstIndex(of: destinationGroup)
            {
                if fromIndex != toIndex
                {
                    withAnimation
                    {
                        self.groups.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                    }
                }
            }
        }
        #endif
    }
}
