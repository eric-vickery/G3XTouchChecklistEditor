//
//  BlankEntryEditView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 2/3/24.
//

import SwiftUI

struct BlankEntryEditView: View 
{
    @Environment(\.dismiss) var dismiss
    
    var body: some View 
    {
        VStack
        {
            Text("No Entry was Selected")
            Spacer()
            Button("Done")
            {
                dismiss()
            }
        }
        .padding()
    }
}

#Preview {
    BlankEntryEditView()
}
