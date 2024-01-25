//
//  ContentView.swift
//  G3XTouchChecklistEditor
//
//  Created by Eric Vickery on 12/29/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @ObservedObject var document: ChecklistFile
    @Environment(\.undoManager) var undoManager
    @State var showGroupEditSheet = false
    @State var selectedGroup: Group = Group()
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore = false

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
                    .onDrop(of: [.checklistGroup], delegate: GroupDropViewDelegate(destinationGroup: group, document: document, draggedGroup: selectedGroup))
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
                        Button()
                        {
                            document.duplicateGroup(group.id)
                        }
                    label:
                        {
                            Label("Duplicate", systemImage: "plus.square.on.square")
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
                            document.setDefaultGroup(group.id)
                        }
                    label:
                        {
                            Label("Default", systemImage: group.isDefault ? "checkmark.square.fill" : "checkmark.square")
                                .labelStyle(.titleAndIcon)
                        }
                        Divider()
                        Button ()
                        {
                            document.addGroup(Group(), after: group.id)
                        }
                    label:
                        {
                            Label("Add Group", systemImage: "plus.app")
                                .labelStyle(.titleAndIcon)
                        }
                        Button ()
                        {
                            group.addChecklist(Checklist())
                        }
                    label:
                        {
                            Label("Add Checklist", systemImage: "plus.app")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
//        .overlay()
//        {
//            if !hasLaunchedBefore
//            {
//                TutorialView()
//            }
//        }
        .sheet(isPresented: $showGroupEditSheet)
        {
            GroupEditView(group: selectedGroup)
        }
    }
}

#Preview {
    MainView(document: ChecklistFile())
}

struct GroupDropViewDelegate: DropDelegate
{
    let destinationGroup: Group
    var document: ChecklistFile
    var draggedGroup: Group
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        #if os(macOS)
        if let fromIndex = document.groups.firstIndex(of: draggedGroup), let toIndex = document.groups.firstIndex(of: destinationGroup)
        {
            if fromIndex != toIndex
            {
                withAnimation
                {
                    document.moveGroups(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                }
            }
        }
        #endif
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        #if os(iOS)
        if let fromIndex = document.groups.firstIndex(of: draggedGroup), let toIndex = document.groups.firstIndex(of: destinationGroup)
        {
            if fromIndex != toIndex
            {
                withAnimation
                {
                    document.moveGroups(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                }
            }
        }
        #endif
    }
}
