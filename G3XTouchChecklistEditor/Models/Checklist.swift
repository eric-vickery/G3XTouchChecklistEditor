//
//  Checklist.swift
//  G3XTouchChecklistEditor
//
//  Created by Eric Vickery on 12/30/23.
//

import Foundation
import SwiftUI

class Checklist: ObservableObject, Identifiable
{
    static let header = "(0"
    static let footer = ")"

    var undoManager: UndoManager?
    @Published var id = UUID()
    @Published var name = ""
    @Published var entries:[Entry] = []
    // Don't like this UI data here but these will stay here until I come up with a better way
    @Published var isExpanded = false
#if os(iOS)
    @Published var editMode: EditMode = .inactive
#endif

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
        guard let entries = Entry.parseEntries(&data, parent: self) else
        {
            return nil
        }
        self.entries = entries
        
        if !removeFooter(&data)
        {
            return nil
        }
    }
    
    init()
    {
        name = "Checklist 1"
        entries = [Entry()]
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
//        if fromOffsets.count == 1
//        {
//            undoManager?.registerUndo(withTarget: self)
//            { checklist in
//                checklist.undoManager?.setActionName("Move Checklist Entry")
//                checklist.moveEntries(fromOffsets: IndexSet(integer: toOffset), toOffset: fromOffsets.first!)
//            }
//        }
    }
    
    func removeEntries(atOffsets: IndexSet)
    {
        entries.remove(atOffsets: atOffsets)
    }
    
    func removeEntries(inSet: Set<UUID>)
    {
        let removedEntries: [Entry] = entries.filter( { inSet.contains($0.id) })
        entries.removeAll { inSet.contains($0.id) }
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
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Remove Checklist Entries")
            checklist.addEntries(contentsOf: contentsOf)
        }
    }
    
    func removeEntry(_ entry: Entry)
    {
        entries.removeAll(where: { $0.id == entry.id })
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Remove Checklist Entry")
            checklist.addEntry(entry)
        }
    }
    
    func addEntries(contentsOf: [Entry])
    {
        entries.append(contentsOf: contentsOf)
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Add Checklist Entries")
            checklist.removeEntries(contentsOf: contentsOf)
        }
    }
    
    func addEntry(_ entry: Entry)
    {
        entries.append(entry)
        undoManager?.registerUndo(withTarget: self)
        { checklist in
            checklist.undoManager?.setActionName("Add Checklist Entry")
            checklist.removeEntry(entry)
        }
    }
    
    func getEntry(_ id: UUID) -> Entry?
    {
        return entries.first(where: { $0.id == id })
    }
}
