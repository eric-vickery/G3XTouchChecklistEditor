//
//  ChecklistsView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/1/24.
//

import SwiftUI

struct ChecklistsView: View
{
    @ObservedObjects var checklists: [Checklist]
    @Environment(\.defaultMinListRowHeight) var minRowHeight

    var body: some View
    {
        ForEach(checklists)
        { checklist in
            ChecklistView(checklist: checklist)
        }
    }
}

//#Preview {
//    ChecklistsView()
//}
