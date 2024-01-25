//
//  TutorialView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/19/24.
//

import SwiftUI

struct TutorialView: View 
{
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore = false

    var body: some View
    {
        VStack
        {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            Spacer()
            Button("Close")
            {
//                hasLaunchedBefore = true
            }
        }
    }
}

#Preview {
    TutorialView()
}
