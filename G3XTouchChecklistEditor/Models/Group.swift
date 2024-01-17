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
    @Published var checklists:[Checklist] = []
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
    
    init()
    {
        name = "New Group"
        checklists = [Checklist()]
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
    
}


