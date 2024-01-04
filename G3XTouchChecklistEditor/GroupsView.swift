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

    var body: some View
    {
        group.undoManager = undoManager
        return DisclosureGroup(isExpanded: $group.isExpanded)
        {
            ChecklistsView(checklists: group.checklists)
        }
    label:
        {
            Label(group.name, systemImage: "rectangle.3.group.bubble.left")
        }
#if os(macOS)
        .onTapGesture {
            withAnimation()
            {
                group.isExpanded.toggle()
            }
        }
#endif
        .font(.title2)
    }
}

//#Preview {
//    GroupsView()
//}
