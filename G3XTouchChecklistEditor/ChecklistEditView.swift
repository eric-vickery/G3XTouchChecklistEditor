//
//  ChecklistEditView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/17/24.
//

import SwiftUI

struct ChecklistEditView: View {
    @ObservedObject var checklist: Checklist
    @Environment(\.undoManager) var undoManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View
    {
        VStack
        {
            Form
            {
                TextField("Name", text: $checklist.name)
                Spacer()
                Button("Done")
                {
                    dismiss()
                }
            }
        }
        .padding()
    }
}

//#Preview {
//    ChecklistEditView()
//}
