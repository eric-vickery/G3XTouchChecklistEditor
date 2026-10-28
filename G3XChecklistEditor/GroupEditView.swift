//
//  GroupEditView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/15/24.
//

import SwiftUI

struct GroupEditView: View {
    @ObservedObject var group: Group
    @Environment(\.undoManager) var undoManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View
    {
        VStack
        {
            Form
            {
                TextField("Name", text: $group.name)
                Spacer()
                Button("Done")
                {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .onSubmit 
                {
                    dismiss()
                }
            }
        }
        .padding()
    }
}

//#Preview {
//    GroupEditView()
//}
