//
//  Entry.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/2/24.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

extension UTType
{
    static let checklistEntry = UTType(exportedAs: "com.garmin.g3x.checklist.entry")
}

enum EntryType: String, CaseIterable, Identifiable, CustomStringConvertible
{
    var id: Self {
        return self
    }
    
    case undefined = "c"
    case text = "p"
    case note = "n"
    case subtitle = "t"
    case warning = "w"
    case caution = "a"
    case challenge = "r"
    
    var description: String
    {
        switch self
        {
        case .undefined: return "Undefined"
        case .text: return "Text"
        case .note: return "Note"
        case .subtitle: return "Subtitle"
        case .warning: return "Warning"
        case .caution: return "Caution"
        case .challenge: return "Challange/Response"
        }
    }
}

enum SampleEntryType: Int, CaseIterable
{
    case none = 0
    case textLeft
    case textOne
    case textTwo
    case textThree
    case textFour
    case textCenter
    case noteBlankLines
    case subtitle
    case warning
    case caution
    case challenge
}

enum Justification: String, CaseIterable, Identifiable, CustomStringConvertible
{
    var id: Self {
        return self
    }
    
    case left = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case center = "c"

    var description: String
    {
        switch self
        {
        case .left: return "Left Justified"
        case .one: return "Indent 1 Level"
        case .two: return "Indent 2 Levels"
        case .three: return "Indent 3 Levels"
        case .four: return "Indent 4 Levels"
        case .center: return "Center Justified"
        }
    }
}

class Entry: ObservableObject, Identifiable, Transferable
{
    static let challengeResponseSeparator = "~"
    
    var undoManager: UndoManager?
    @Published var id = UUID()
    @Published var type:EntryType = .undefined
    {
        didSet
        {
            if oldValue != type
            {
                undoManager?.setActionName("Change Type")
                undoManager?.registerUndo(withTarget: self)
                { entry in
                    entry.undoManager?.setActionName("Change Type")
                    entry.type = oldValue
                }
            }
        }
    }
    @Published var justification:Justification = .left
    {
        didSet
        {
            if oldValue != justification
            {
                undoManager?.setActionName("Change Justification")
                undoManager?.registerUndo(withTarget: self)
                { entry in
                    entry.undoManager?.setActionName("Change Justification")
                    entry.justification = oldValue
                }
            }
        }
    }
    @Published var numBlankLinesFollowing:Int = 0
    {
        didSet
        {
            if oldValue != numBlankLinesFollowing
            {
                undoManager?.setActionName("Change Lines")
                undoManager?.registerUndo(withTarget: self)
                { entry in
                    entry.undoManager?.setActionName("Change Lines")
                    entry.numBlankLinesFollowing = oldValue
                }
            }
        }
    }
    @Published var text = ""
    {
        didSet
        {
            if oldValue != text
            {
                undoManager?.setActionName("Change Text")
                undoManager?.registerUndo(withTarget: self)
                { entry in
                    entry.undoManager?.setActionName("Change Text")
                    entry.text = oldValue
                }
            }
        }
    }
    @Published var response = ""
    {
        didSet
        {
            if oldValue != response
            {
                undoManager?.setActionName("Change Response")
                undoManager?.registerUndo(withTarget: self)
                { entry in
                    entry.undoManager?.setActionName("Change Response")
                    entry.response = oldValue
                }
            }
        }
    }

    static var transferRepresentation: some TransferRepresentation
    {
        DataRepresentation(contentType: .checklistEntry)
        { checklistEntry in
            var data = Data()
            return checklistEntry.exportData(&data)
        } 
    importing:
        { data in
            var myData = data
            guard let entry = Entry(&myData) else
            {
                throw "Could not decode transferrable"
            }
            return entry
        }
    }
    
    static func parseEntries(_ data: inout Data) -> [Entry]?
    {
        var entryArray:[Entry]?
        var couldBeMoreEntries = true
        
        repeat
        {
            if let entry = Entry(&data)
            {
                entryArray == nil ? entryArray = [entry] : entryArray!.append(entry)
            }
            else
            {
                couldBeMoreEntries = false
            }
        }
        while couldBeMoreEntries
                
                return entryArray
    }
    
    init?(_ data: inout Data)
    {
        if !parseHeader(&data)
        {
            return nil
        }
        if !parseText(&data)
        {
            return nil
        }
        
        self.numBlankLinesFollowing = checkForBlankLines(&data)
    }
    
    init(_ sampleEntryType: SampleEntryType = .none)
    {
        switch sampleEntryType
        {
        case .none:
            type = .undefined
            justification = .left
            text = "New Item"
        case .textLeft:
            type = .text
            justification = .left
            text = "Plain Text Left Justified"
        case .textOne:
            type = .text
            justification = .one
            text = "Plain Text Indented 1 Level"
        case .textTwo:
            type = .text
            justification = .two
            text = "Plain Text Indented 2 Levels"
        case .textThree:
            type = .text
            justification = .three
            text = "Plain Text Indented 3 Levels"
        case .textFour:
            type = .text
            justification = .four
            text = "Plain Text Indented 4 Levels"
        case .textCenter:
            type = .text
            justification = .center
            text = "Plain Text Center Justified"
        case .noteBlankLines:
            type = .note
            justification = .left
            numBlankLinesFollowing = 5
            text = "Note with 5 blank lines"
        case .subtitle:
            type = .subtitle
            justification = .left
            text = "Subtitle Type"
        case .warning:
            type = .warning
            justification = .center
            text = "This is a Warning Center Justified"
        case .caution:
            type = .caution
            justification = .left
            text = "This is a Caution"
        case .challenge:
            type = .challenge
            justification = .left
            text = "Challenge"
            response = "Response"
        }
    }
    
    func exportData(_ data: inout Data) -> Data
    {
        data.append(contentsOf: type.rawValue.data(using: .ascii)!)
        data.append(contentsOf: justification.rawValue.data(using: .ascii)!)
        data.append(contentsOf: text.data(using: .ascii)!)
        if type == .challenge
        {
            data.append(contentsOf: Entry.challengeResponseSeparator.data(using: .ascii)!)
            data.append(contentsOf: response.data(using: .ascii)!)
        }
        data.append(contentsOf: ChecklistFile.separator)
        if numBlankLinesFollowing > 0
        {
            for _ in 1...numBlankLinesFollowing
            {
                data.append(contentsOf: ChecklistFile.separator)
            }
        }
        return data
    }
    
    func parseHeader(_ data: inout Data) -> Bool
    {
        let byte1 = data.first!
        
        guard let type = EntryType(rawValue: String(UnicodeScalar(byte1))) else
        {
            return false
        }
        _ = data.popFirst()
        self.type = type
        
        let byte2 = data.popFirst()!
        guard let justification = Justification(rawValue: String(UnicodeScalar(byte2))) else
        {
            return false
        }
        self.justification = justification
        
        return true
    }
    
    func checkForBlankLines(_ data: inout Data) -> Int
    {
        var numBlankLines = 0
        
        var byte = data.first
        
        while byte == 0x0D
        {
            // Remove the /r/n
            _ = data.popFirst()
            _ = data.popFirst()
            numBlankLines += 1
            byte = data.first
        }
        
        return numBlankLines
    }
    
    func parseString(_ data: inout Data, terminator: UInt8, removeTrailing: Bool) -> String?
    {
        var foundString:String?
        
        if let lastIndex = data.firstIndex(of: terminator)
        {
            let range:Range<Data.Index> = data.startIndex..<lastIndex
            let subData = data.subdata(in: range)
            data.removeSubrange(range)
            if removeTrailing
            {
                // Now remove the /r/n
                _ = data.popFirst()
                _ = data.popFirst()
            }
            
            foundString = String(bytes: subData, encoding: .utf8)
        }
        
        return foundString
    }
    
    func parseText(_ data: inout Data) -> Bool
    {
        if self.type == .challenge
        {
            // Split at the ~
            guard let name = parseString(&data, terminator: 0x7E, removeTrailing: false) else
            {
                return false
            }
            self.text = name
            
            // Remove the ~
            _ = data.popFirst()
            
            guard let response = parseString(&data, terminator: 0x0D, removeTrailing: true) else
            {
                return false
            }
            self.response = response
            return true
        }
        else
        {
            if let name = parseString(&data, terminator: 0x0D, removeTrailing: true)
            {
                self.text = name
                return true
            }
            return false
        }
    }
    
    func duplicate() -> Entry
    {
        let newEntry = Entry()
        newEntry.text = self.text
        newEntry.type = self.type
        newEntry.justification = self.justification
        newEntry.response = self.response
        newEntry.numBlankLinesFollowing = self.numBlankLinesFollowing
        
        return newEntry
    }
}

extension String: LocalizedError
{
    public var errorDescription: String? { return self }
}
