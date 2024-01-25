//
//  Group.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/2/24.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

extension UTType
{
    static let checklistGroup = UTType(exportedAs: "com.garmin.g3x.checklist.group")
}

class Group: ObservableObject, Identifiable, Transferable, Equatable
{
    static let header = "<0"
    static let footer = ">"

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
                { group in
                    group.undoManager?.setActionName("Change Name")
                    group.name = oldValue
                }
            }
        }
    }
    @Published var checklists:[Checklist] = []
    @Published var isDefault = false
    // Don't like this UI data here but these will stay here until I come up with a better way
    @Published var isExpanded = false

    static func == (lhs: Group, rhs: Group) -> Bool 
    {
        return lhs.id == rhs.id
    }
    
    static var transferRepresentation: some TransferRepresentation
    {
        DataRepresentation(contentType: .checklistGroup)
        { checklistGroup in
            var data = Data()
            return checklistGroup.exportData(&data)
        }
    importing:
        { data in
            var myData = data
            guard let group = Group(&myData) else
            {
                throw "Could not decode transferrable"
            }
            return group
        }
    }
    
    static func parseGroups(_ data: inout Data) -> [Group]?
    {
        var groupArray:[Group]?
        var couldBeMoreGroups = true
        
        repeat
        {
            if let group = Group(&data)
            {
                groupArray == nil ? groupArray = [group] : groupArray!.append(group)
            }
            else
            {
                couldBeMoreGroups = false
            }
        }
        while couldBeMoreGroups
                
                return groupArray
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
        guard let checklists = Checklist.parseChecklists(&data) else
        {
            return nil
        }
        self.checklists = checklists
        
        if !removeFooter(&data)
        {
            return nil
        }
    }
    
    init(_ sampleGroup: Bool = false)
    {
        if sampleGroup
        {
            name = "Sample Group"
            checklists = [Checklist(true)]
        }
        else
        {
            name = "New Group"
            checklists = [Checklist()]
        }
    }
    
    func exportData(_ data: inout Data) -> Data
    {
        data.append(contentsOf: Group.header.data(using: .ascii)!)
        data.append(contentsOf: name.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        
        for checklist in checklists
        {
            checklist.exportData(&data)
        }
        data.append(contentsOf: Group.footer.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        
        return data
    }
    
    func validateHeader(_ data: inout Data) -> Bool
    {
        let byte1 = data.first
        if byte1 != UInt8(ascii: "<")
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
        if (byte1 != UInt8(ascii: ">"))
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
    
    func moveChecklists(fromOffsets: IndexSet, toOffset: Int)
    {
        checklists.move(fromOffsets: fromOffsets, toOffset: toOffset)
        // Only undo if we moved one checklist
        if fromOffsets.count == 1
        {
            undoManager?.setActionName("Move Checklist")
            undoManager?.registerUndo(withTarget: self)
            { group in
                group.undoManager?.setActionName("Move Checklist")
                let fromIndex = fromOffsets.first!
                group.moveChecklists(fromOffsets: IndexSet(integer: (toOffset > fromIndex ? toOffset - 1 : toOffset)), toOffset: (fromIndex > toOffset ? (fromIndex + 1) : fromIndex))
            }
        }
    }
    
    func removeChecklists(atOffsets: IndexSet)
    {
        checklists.remove(atOffsets: atOffsets)
    }
    
    func removeChecklists(inSet: Set<UUID>)
    {
        let removedChecklists: [Checklist] = checklists.filter( { inSet.contains($0.id) })
        checklists.removeAll { inSet.contains($0.id) }

        undoManager?.setActionName("Remove Checklists")
        undoManager?.registerUndo(withTarget: self)
        { group in
            group.undoManager?.setActionName("Remove Checklists")
            group.addChecklists(contentsOf: removedChecklists)
        }
    }
    
    func removeChecklists(contentsOf: [Checklist])
    {
        checklists.removeAll(where: { checklist in
            contentsOf.contains(where: {checklistToRemove in
                checklistToRemove.id == checklist.id
            })
        })
        undoManager?.setActionName("Remove Checklists")
        undoManager?.registerUndo(withTarget: self)
        { group in
            group.undoManager?.setActionName("Remove Checklists")
            group.addChecklists(contentsOf: contentsOf)
        }
    }
    
    func removeChecklist(_ checklist: Checklist)
    {
        checklists.removeAll(where: { $0.id == checklist.id })

        undoManager?.setActionName("Remove Checklist")
        undoManager?.registerUndo(withTarget: self)
        { group in
            group.undoManager?.setActionName("Remove Checklist")
            group.addChecklist(checklist)
        }
    }
    
    func addChecklists(contentsOf: [Checklist])
    {
        checklists.append(contentsOf: contentsOf)

        undoManager?.setActionName("Add Checklists")
        undoManager?.registerUndo(withTarget: self)
        { group in
            group.undoManager?.setActionName("Add Checklists")
            group.removeChecklists(contentsOf: contentsOf)
        }
    }
    
    func addChecklist(_ checklist: Checklist)
    {
        checklists.append(checklist)

        undoManager?.setActionName("Add Checklist")
        undoManager?.registerUndo(withTarget: self)
        { group in
            group.undoManager?.setActionName("Add Checklist")
            group.removeChecklist(checklist)
        }
    }
    
    func addChecklist(_ checklist: Checklist, after: UUID?)
    {
        guard let after else
        {
            return
        }
        if let itemIndex = checklists.firstIndex(where: { $0.id == after })
        {
            checklists.insert(checklist, at: itemIndex + 1)

            undoManager?.setActionName("Add Checklist")
            undoManager?.registerUndo(withTarget: self)
            { group in
                group.undoManager?.setActionName("Add Checklist")
                group.removeChecklist(checklist)
            }
        }
    }
    
    func duplicateChecklist(_ id: UUID?)
    {
        if let id, let checklistToDuplicate = getChecklist(id)
        {
            let duplicate = checklistToDuplicate.duplicate()
            addChecklist(duplicate, after: id)
        }
    }
    
    func getChecklist(_ id: UUID) -> Checklist?
    {
        return checklists.first(where: { $0.id == id })
    }
    
    func setDefaultChecklist(_ id: UUID)
    {
        for checklist in checklists
        {
            if checklist.id == id
            {
                checklist.isDefault = true
            }
            else
            {
                checklist.isDefault = false
            }
        }
        self.objectWillChange.send()
    }
    
    func setDefaultChecklist(byIndex: Int)
    {
        if byIndex < checklists.count - 1
        {
            checklists[byIndex].isDefault = true
            
            self.objectWillChange.send()
        }
    }
    
    func duplicate() -> Group
    {
        let newGroup = Group()
        newGroup.name = self.name + " - Copy"
        newGroup.checklists = self.checklists.map({ $0.duplicate() })
        
        return newGroup
    }

    func getDefaultChecklistIndex() -> Int
    {
        if let index = checklists.firstIndex(where: { $0.isDefault })
        {
            return index
        }
        return 0
    }
    
    func getDefaultChecklist() -> Checklist?
    {
        return checklists.first(where: { $0.isDefault })
    }
}


