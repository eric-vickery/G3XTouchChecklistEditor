//
//  EntryEditView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/3/24.
//

import SwiftUI

struct EntryEditView: View 
{
    @ObservedObject var entry: Entry
    @Environment(\.undoManager) var undoManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View
    {
        Form
        {
            Picker("Type", selection: $entry.type) {
                ForEach(EntryType.allCases) { type in
                    Text(type.description)
                }
            }
            TextField("Text", text: $entry.text)
            TextField("Response", text: $entry.response)
                .disabled(entry.type != .challenge)
            Picker("Justification", selection: $entry.justification) {
                ForEach(Justification.allCases) { justification in
                    if !(entry.type == .challenge && justification == .center)
                    {
                        Text(justification.description)
                    }
                }
            }
            Stepper("\(entry.numBlankLinesFollowing) blank lines after", value: $entry.numBlankLinesFollowing, in: 0...5)
            Spacer()
            Button("Done")
            {
                dismiss()
            }
        }
        .padding()
    }
}

//#Preview {
//    EntryEditView()
//}
