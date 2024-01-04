//
//  EntryView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 12/31/23.
//

import SwiftUI

struct EntryView: View {
    @ObservedObject var entry: Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.undoManager) var undoManager

    var body: some View
    {
        entry.undoManager = undoManager
        return VStack
        {
            HStack
            {
                switch entry.type
                {
                case .undefined, .text:
                    Text(entry.text)
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(justification: entry.justification), bottom: 0, trailing: 10))
                case .note:
                    Text("NOTE: " + entry.text)
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(justification: entry.justification), bottom: 0, trailing: 10))
                case .subtitle:
                    Text(entry.text)
                        .font(.title2)
//                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(justification: entry.justification), bottom: 0, trailing: 10))
                case .warning:
                    Text("WARNING: " + entry.text)
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(justification: entry.justification), bottom: 0, trailing: 10))
                case .caution:
                    Text("CAUTION: " + entry.text)
                        .font(.title2)
//                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .foregroundStyle(.white)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(justification: entry.justification), bottom: 0, trailing: 10))
                case .challenge:
                    HStack
                    {
                        Image(systemName: "square")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        Text(entry.text)
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        Text(String(repeating: ".", count: 200))
                            .lineLimit(1)
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        Text(entry.response)
                            .font(.title2)
                            .foregroundStyle(.cyan)
                    }
                    .padding(EdgeInsets(top: 0, leading: getPaddingAmount(justification: entry.justification), bottom: 0, trailing: 0))
                }
                Spacer()
            }
            BlankLinesView(entry: entry)
        }
//        .onLongPressGesture
//        {
//            print("You pressed on \(self.entry.text)")
//        }
    }
}
//                                            Button(action: {
//
//                                            }, label: {
//                                                Image(systemName: "pencil")
//                                            })
//                                            .cornerRadius(5)
//                                            Spacer()
//                                    Picker("Type", selection: $document.groups[groupIndex].checklists[checklistIndex].entries[entryIndex].type) {
//                                        Text("Undefined").tag(EntryType.undefined)
//                                        Text("Text").tag(EntryType.text)
//                                        Text("Note").tag(EntryType.note)
//                                        Text("Subtitle").tag(EntryType.subtitle)
//                                        Text("Warning").tag(EntryType.warning)
//                                        Text("Caution").tag(EntryType.caution)
//                                        Text("Challenge").tag(EntryType.challenge)
//                                        }

private func getPaddingAmount(justification: Justification) -> CGFloat
{
    var paddingAmountForIndent: CGFloat = 0
    
    switch justification
    {
    case .left:
        paddingAmountForIndent = 10
    case .one:
        paddingAmountForIndent = 30
    case .two:
        paddingAmountForIndent = 50
    case .three:
        paddingAmountForIndent = 70
    case .four:
        paddingAmountForIndent = 90
    case .center:
        paddingAmountForIndent = 15
    }
    return paddingAmountForIndent
}

//#Preview {
//    EntryView()
//}

struct BlankLinesView: View {
    @ObservedObject var entry: Entry
    
    var body: some View
    {
        if entry.numBlankLinesFollowing == 0
        {
            EmptyView()
        }
        else
        {
            VStack
            {
                ForEach((1...entry.numBlankLinesFollowing), id: \.self)
                { _ in
                    Text("")
                }
            }
        }
    }
}
