//
//  GroupsView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/2/24.
//

import SwiftUI

struct GroupsView: View {
    @ObservedObject var group: Group
    @Environment(\.undoManager) var undoManager
    @State var showGroupEditSheet = false
    @State var selectedGroup: Group = Group()

    var body: some View
    {
        group.undoManager = undoManager
        
        return DisclosureGroup(isExpanded: $group.isExpanded)
        {
            ChecklistsView(group: group)
        }
    label:
        {
            HStack
            {
                Label(group.name, systemImage: "rectangle.3.group.bubble.left")
                    .onTapGesture(count: 2)
                {
                    showGroupEditSheet.toggle()
                }
                .onTapGesture
                {
                    withAnimation()
                    {
                        group.isExpanded.toggle()
                    }
                }
            }
        }
        .font(.title2)
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
#if os(macOS)
        .onTapGesture {
            withAnimation()
            {
                group.isExpanded.toggle()
            }
        }
#endif
        .sheet(isPresented: $showGroupEditSheet)
        {
            GroupEditView(group: group)
        }
    }
}

//#Preview {
//    GroupsView()
//}
