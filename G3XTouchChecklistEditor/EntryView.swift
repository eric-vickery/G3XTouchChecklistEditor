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
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(entry.justification), bottom: 0, trailing: 10))
                        .frame(maxWidth: .infinity, alignment: getAlignment(entry.justification))
                case .note:
                    Text("NOTE: " + entry.text)
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(entry.justification), bottom: 0, trailing: 10))
                        .frame(maxWidth: .infinity, alignment: getAlignment(entry.justification))
                case .subtitle:
                    Text(entry.text)
                        .font(.title2)
//                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(entry.justification), bottom: 0, trailing: 10))
                        .frame(maxWidth: .infinity, alignment: getAlignment(entry.justification))
                case .warning:
                    Text("WARNING: " + entry.text)
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(entry.justification), bottom: 0, trailing: 10))
                        .frame(maxWidth: .infinity, alignment: getAlignment(entry.justification))
                case .caution:
                    Text("CAUTION: " + entry.text)
                        .font(.title2)
//                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .foregroundStyle(.white)
                        .padding(EdgeInsets(top: 0, leading: getPaddingAmount(entry.justification), bottom: 0, trailing: 10))
                        .frame(maxWidth: .infinity, alignment: getAlignment(entry.justification))
                case .challenge:
                    HStack(alignment: .top)
                    {
                        Image(systemName: "square")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        Text(entry.text)
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        Text(String(repeating: ".", count: 400))
                            .lineLimit(1)
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        Text(entry.response)
                            .font(.title2)
                            .foregroundStyle(.cyan)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(EdgeInsets(top: 0, leading: getPaddingAmount(entry.justification), bottom: 0, trailing: 0))
                }
                Spacer()
            }
            BlankLinesView(entry: entry)
        }
    }
}

private func getPaddingAmount(_ justification: Justification) -> CGFloat
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
        paddingAmountForIndent = 0
    }
    return paddingAmountForIndent
}

private func getAlignment(_ justification: Justification) -> Alignment
{
    var alignment = Alignment.leading
    
    if justification == .center
    {
        alignment = .center
    }
    
    return alignment
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
