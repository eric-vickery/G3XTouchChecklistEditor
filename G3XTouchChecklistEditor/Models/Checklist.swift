//
//  Checklist.swift
//  G3XTouchChecklistEditor
//
//  Created by Eric Vickery on 12/30/23.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType
{
    static let checklist = UTType(exportedAs: "com.garmin.g3x.checklist")
}

class Checklist: ObservableObject, Identifiable, Equatable
{
    static let header = "(0"
    static let footer = ")"

    var undoManager: UndoManager?
    @Published var id = UUID()
    @Published var name = ""
    {
        didSet
        {
            if oldValue != name
            {
                undoManager?.setActionName("Change Name")
                undoManager?.registerUndo(withTarget: self)
                { checklist in
                    checklist.undoManager?.setActionName("Change Name")
                    checklist.name = oldValue
                }
            }
        }
    }
    @Published var entries:[Entry] = []
    @Published var isDefault = false
    // Don't like this UI data here but these will stay here until I come up with a better way
    @Published var isExpanded = false

    static func == (lhs: Checklist, rhs: Checklist) -> Bool
    {
        return lhs.id == rhs.id
    }
    
    static func parseChecklists(_ data: inout Data) -> [Checklist]?
    {
        var checklistArray:[Checklist]?
        var couldBeMoreChecklists = true
        
        repeat
        {
            if let checklist = Checklist(&data)
            {
                checklistArray == nil ? checklistArray = [checklist] : checklistArray!.append(checklist)
            }
            else
            {
                couldBeMoreChecklists = false
            }
        }
        while couldBeMoreChecklists
                
                return checklistArray
    }
    
    init?(_ data: inout Data)
    {
        if !validateHeader(&data)
        {
            return nil
        }
        if !parseName(&data)
        {
            return nil
        }
        guard let entries = Entry.parseEntries(&data) else
        {
            return nil
        }
        self.entries = entries
        
        if !removeFooter(&data)
        {
            return nil
        }
    }
    
    init(_ sampleChecklist: Bool = false)
    {
        if sampleChecklist
        {
            name = "Sample Checklist"
            entries = createSampleEntries()
        }
        else
        {
            name = "Checklist 1"
            entries = [Entry()]
        }
    }
    
    func exportData(_ data: inout Data) -> Void
    {
        data.append(contentsOf: Checklist.header.data(using: .ascii)!)
        data.append(contentsOf: name.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        
        for entry in entries
        {
            _ = entry.exportData(&data)
        }
        data.append(contentsOf: Checklist.footer.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
    }
    
    func validateHeader(_ data: inout Data) -> Bool
    {
        let byte1 = data.first
        if byte1 != UInt8(ascii: "(")
        {
            return false
        }
        // Remove the header
        _ = data.popFirst()
        _ = data.popFirst()
        
        return true
    }
    
    func removeFooter(_ data: inout Data) -> Bool
    {
        // See if we have the correct footer
        let byte1 = data.popFirst()
        if byte1 != UInt8(ascii: ")")
        {
            return false
        }
        
        // Remove the trailing /r/n
        _ = data.popFirst()
        _ = data.popFirst()
        
        return true
    }
    
    func parseString(_ data: inout Data) -> String?
    {
        var foundString:String?
        
        if let lastIndex = data.firstIndex(of: 0x0D)
        {
            let range:Range<Data.Index> = data.startIndex..<lastIndex
            let subData = data.subdata(in: range)
            data.removeSubrange(range)
            // Now remove the /r/n
            _ = data.popFirst()
            _ = data.popFirst()
            foundString = String(bytes: subData, encoding: .utf8)
        }
        
        return foundString
    }
    
    func parseName(_ data: inout Data) -> Bool
    {
        if let name = parseString(&data)
        {
            self.name = name
            return true
        }
        return false
    }
    
    func moveEntries(fromOffsets: IndexSet, toOffset: Int)
    {
        entries.move(fromOffsets: fromOffsets, toOffset: toOffset)
        // Only undo if we moved one entry
        if fromOffsets.count == 1
        {
            undoManager?.setActionName("Move Checklist Entry")
            undoManager?.registerUndo(withTarget: self)
            { checklist in
                checklist.undoManager?.setActionName("Move Checklist Entry")
                let fromIndex = fromOffsets.first!
                checklist.moveEntries(fromOffsets: IndexSet(integer: (toOffset > fromIndex ? toOffset - 1 : toOffset)), toOffset: (fromIndex > toOffset ? (fromIndex + 1) : fromIndex))
            }
        }
    }
    
    func removeEntries(atOffsets: IndexSet)
    {
        entries.remove(atOffsets: atOffsets)
    }
    
    func removeEntries(inSet: Set<UUID>)
    {
        let removedEntries: [Entry] = entries.filter( { inSet.contains($0.id) })
        entries.removeAll { inSet.contains($0.id) }
        
        undoManager?.setActionName("Remove Checklist Entries")
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Remove Checklist Entries")
            checklist.addEntries(contentsOf: removedEntries)
        }
    }
    
    func removeEntries(contentsOf: [Entry])
    {
        entries.removeAll(where: { entry in
            contentsOf.contains(where: {entryToRemove in
                entryToRemove.id == entry.id
            })
        })
        undoManager?.setActionName("Remove Checklist Entries")
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Remove Checklist Entries")
            checklist.addEntries(contentsOf: contentsOf)
        }
    }
    
    func removeEntry(_ entry: Entry)
    {
        entries.removeAll(where: { $0.id == entry.id })

        undoManager?.setActionName("Remove Checklist Entry")
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Remove Checklist Entry")
            checklist.addEntry(entry)
        }
    }
    
    func addEntries(contentsOf: [Entry])
    {
        entries.append(contentsOf: contentsOf)
        
        undoManager?.setActionName("Add Checklist Entries")
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Add Checklist Entries")
            checklist.removeEntries(contentsOf: contentsOf)
        }
    }
    
    func addEntry(_ entry: Entry)
    {
        entries.append(entry)

        undoManager?.setActionName("Add Checklist Entry")
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Add Checklist Entry")
            checklist.removeEntry(entry)
        }
    }
    
    func addEntry(_ entry: Entry, after: UUID?)
    {
        guard let after else
        {
            return
        }
        if let itemIndex = entries.firstIndex(where: { $0.id == after })
        {
            entries.insert(entry, at: itemIndex + 1)

            undoManager?.setActionName("Add Checklist Entry")
            undoManager?.registerUndo(withTarget: self)
            { checklist in
                checklist.undoManager?.setActionName("Add Checklist Entry")
                checklist.removeEntry(entry)
            }
        }
    }
    
    func duplicateEntry(_ id: UUID?)
    {
        if let id, let entryToDuplicate = getEntry(id)
        {
            let duplicate = entryToDuplicate.duplicate()
            addEntry(duplicate, after: id)
        }
    }
    
    func duplicateEntries(_ ids: Set<UUID>)
    {
        for id in ids
        {
            if let entryToDuplicate = getEntry(id)
            {
                let duplicate = entryToDuplicate.duplicate()
                addEntry(duplicate, after: id)
            }
        }
    }
    
    func getEntry(_ id: UUID) -> Entry?
    {
        return entries.first(where: { $0.id == id })
    }
    
    func duplicate() -> Checklist
    {
        let newChecklist = Checklist()
        newChecklist.name = self.name + " - Copy"
        newChecklist.entries = self.entries.map({ $0.duplicate() })
        
        return newChecklist
    }
    
    func createSampleEntries() -> [Entry]
    {
        var entries = [Entry]()
        
        for entryType in SampleEntryType.allCases
        {
            if entryType != .none
            {
                let entry = Entry(entryType)
                entries.append(entry)
            }
        }
        
        return entries
    }
}
