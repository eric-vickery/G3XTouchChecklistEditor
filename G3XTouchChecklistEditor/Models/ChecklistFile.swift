//
//  ChecklistFile.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/2/24.
//

import Foundation
import CrcSwift
import UniformTypeIdentifiers
import SwiftUI

extension UInt32
{
    var bytes: [UInt8]
    {
        var bend = bigEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &bend)
        {
            $0.withMemoryRebound(to: UInt8.self, capacity: count)
            {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }
    
    var reverseBytes: [UInt8]
    {
        var bend = bigEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &bend)
        {
            $0.withMemoryRebound(to: UInt8.self, capacity: count)
            {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr).reversed()
    }
}

extension UTType
{
    static let checklistDocument = UTType(exportedAs: "com.garmin.g3x.checklistfile")
}

class ChecklistFile: FileDocument, ObservableObject, Identifiable
{
    static var readableContentTypes: [UTType] = [.checklistDocument]
    
    static let footer = "END"
    static let separator:[UInt8] = [0x0D, 0x0A]
    
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
                { checklistFile in
                    checklistFile.undoManager?.setActionName("Change Name")
                    checklistFile.name = oldValue
                }
            }
        }
    }
    @Published var makeAndModel = ""
    {
        didSet
        {
            if oldValue != makeAndModel
            {
                undoManager?.setActionName("Change Make")
                undoManager?.registerUndo(withTarget: self)
                { checklistFile in
                    checklistFile.undoManager?.setActionName("Change Make")
                    checklistFile.makeAndModel = oldValue
                }
            }
        }
    }
    @Published var aircraftInfo = ""
    {
        didSet
        {
            if oldValue != aircraftInfo
            {
                undoManager?.setActionName("Change Info")
                undoManager?.registerUndo(withTarget: self)
                { checklistFile in
                    checklistFile.undoManager?.setActionName("Change Info")
                    checklistFile.aircraftInfo = oldValue
                }
            }
        }
    }
    @Published var manufacturerID = ""
    {
        didSet
        {
            if oldValue != manufacturerID
            {
                undoManager?.setActionName("Change Manufacturer")
                undoManager?.registerUndo(withTarget: self)
                { checklistFile in
                    checklistFile.undoManager?.setActionName("Change Manufacturer")
                    checklistFile.manufacturerID = oldValue
                }
            }
        }
    }
    @Published var copyright = ""
    {
        didSet
        {
            if oldValue != copyright
            {
                undoManager?.setActionName("Change Copyright")
                undoManager?.registerUndo(withTarget: self)
                { checklistFile in
                    checklistFile.undoManager?.setActionName("Change Copyright")
                    checklistFile.copyright = oldValue
                }
            }
        }
    }
    var magicHeader1:[UInt8] = [0xF0, 0xF0, 0xF0, 0xF0]
    var magicHeader2:[UInt8] = [0x00, 0x01]
    @Published var groups:[Group] = []
    var defaultGroupIndex:Int = 0
    var defaultChecklistIndex:Int = 0
    // Don't like this UI data here but these will stay here until I come up with a better way
    @Published var isExpanded = false
#if os(iOS)
    @Published var editMode: EditMode = .inactive
#endif

    func validateCRC(_ data: Data) -> Bool
    {
        let manualCrc32 = CrcSwift.computeCrc32(data, initialCrc: 0xFFFFFFFF, polynom: 0x04C11DB7, xor: 0x00000000, refIn: true, refOut: true)
        return manualCrc32 == 0
    }
    
    func calculateAndAppendCRC(_ data: inout Data) -> Void
    {
        let manualCrc32 = CrcSwift.computeCrc32(data, initialCrc: 0xFFFFFFFF, polynom: 0x04C11DB7, xor: 0x00000000, refIn: true, refOut: true)
        data.append(contentsOf: manualCrc32.reverseBytes)
    }
    
    required init(configuration: ReadConfiguration) throws
    {
        guard let loadedData = configuration.file.regularFileContents else
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        var data = loadedData
        
        if !validateCRC(data)
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        if !validateMagicHeader1(&data)
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        if !validateMagicHeader2(&data)
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        if !parseName(&data)
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        if !parseMakeAndModel(&data)
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        if !parseAircraftInfo(&data)
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        if !parseManufacturerID(&data)
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        if !parseCopyright(&data)
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        guard let groups = Group.parseGroups(&data) else
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.groups = groups
        setDefaultGroup(byIndex: defaultGroupIndex)
        setDefaultChecklist(byIndex: defaultChecklistIndex)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
    {
        let data = try exportData()
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        return fileWrapper
    }
    
    init()
    {
        name = "Blank Checklist"
        makeAndModel = "Fast Plane"
        aircraftInfo = "Some Data"
        manufacturerID = "Manufacturer"
        copyright = "2024"
        groups = [Group]()
        groups.append(Group(true))
        groups.append(Group())
    }
    
    init?(_ data: inout Data)
    {
        if !validateMagicHeader1(&data)
        {
            return nil
        }
        if !validateMagicHeader2(&data)
        {
            return nil
        }
        if !parseName(&data)
        {
            return nil
        }
        if !parseMakeAndModel(&data)
        {
            return nil
        }
        if !parseAircraftInfo(&data)
        {
            return nil
        }
        if !parseManufacturerID(&data)
        {
            return nil
        }
        if !parseCopyright(&data)
        {
            return nil
        }
        guard let groups = Group.parseGroups(&data) else
        {
            return nil
        }
        self.groups = groups
        setDefaultGroup(byIndex: defaultGroupIndex)
        setDefaultChecklist(byIndex: defaultChecklistIndex)
    }
    
    func exportData() throws -> Data
    {
        defaultGroupIndex = getDefaultGroupIndex()
        defaultChecklistIndex = getDefaultChecklistIndex()
        
        var data = Data()
        
        data.append(contentsOf: magicHeader1)
        // TODO Need to get the default group and checklist in here
        data.append(contentsOf: magicHeader2)
        data.append(UInt8(defaultGroupIndex))
        data.append(UInt8(defaultChecklistIndex))
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: name.data(using: .ascii) ?? Data(count: 1))
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: makeAndModel.data(using: .ascii) ?? Data(count: 1))
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: aircraftInfo.data(using: .ascii) ?? Data(count: 1))
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: manufacturerID.data(using: .ascii) ?? Data(count: 1))
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: copyright.data(using: .ascii) ?? Data(count: 1))
        data.append(contentsOf: ChecklistFile.separator)
        for group in groups
        {
            _ = group.exportData(&data)
        }
        data.append(contentsOf: ChecklistFile.footer.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        calculateAndAppendCRC(&data)
        return data
    }
    
    func validateMagicHeader1(_ data: inout Data) -> Bool
    {
        // Pull off the first 4 bytes
        let byte1 = data.popFirst()
        let byte2 = data.popFirst()
        let byte3 = data.popFirst()
        let byte4 = data.popFirst()
        
        return byte1 == 0xF0 && byte2 == 0xF0 && byte3 == 0xF0 && byte4 == 0xF0
    }
    
    func validateMagicHeader2(_ data: inout Data) -> Bool
    {
        // Pull off 6 bytes
        let byte1 = data.popFirst()
        let byte2 = data.popFirst()
        let byte3 = data.popFirst()
        let byte4 = data.popFirst()
        let byte5 = data.popFirst()
        let byte6 = data.popFirst()
        
        defaultGroupIndex = Int(byte3!)
        defaultChecklistIndex = Int(byte4!)
        
        return byte1 == 0x00 && byte2 == 0x01 && byte5 == 0x0D && byte6 == 0x0A
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
    
    func parseMakeAndModel(_ data: inout Data) -> Bool
    {
        if let name = parseString(&data)
        {
            self.makeAndModel = name
            return true
        }
        return false
    }
    
    func parseAircraftInfo(_ data: inout Data) -> Bool
    {
        if let name = parseString(&data)
        {
            self.aircraftInfo = name
            return true
        }
        return false
    }
    
    func parseManufacturerID(_ data: inout Data) -> Bool
    {
        if let name = parseString(&data)
        {
            self.manufacturerID = name
            return true
        }
        return false
    }
    
    func parseCopyright(_ data: inout Data) -> Bool
    {
        if let name = parseString(&data)
        {
            self.copyright = name
            return true
        }
        return false
    }
    
    func moveGroups(fromOffsets: IndexSet, toOffset: Int)
    {
        groups.move(fromOffsets: fromOffsets, toOffset: toOffset)
        // Only undo if we moved one group
        if fromOffsets.count == 1
        {
            undoManager?.setActionName("Move Group")
            undoManager?.registerUndo(withTarget: self)
            { checklistFile in
                checklistFile.undoManager?.setActionName("Move Group")
                let fromIndex = fromOffsets.first!
                checklistFile.moveGroups(fromOffsets: IndexSet(integer: (toOffset > fromIndex ? toOffset - 1 : toOffset)), toOffset: (fromIndex > toOffset ? (fromIndex + 1) : fromIndex))
            }
        }
    }
    
    func removeGroups(atOffsets: IndexSet)
    {
        groups.remove(atOffsets: atOffsets)
    }
    
    func removeGroups(inSet: Set<UUID>)
    {
        let removedGroups: [Group] = groups.filter( { inSet.contains($0.id) })
        groups.removeAll { inSet.contains($0.id) }

        undoManager?.setActionName("Remove Groups")
        undoManager?.registerUndo(withTarget: self)
        { checklistFile in
            checklistFile.undoManager?.setActionName("Remove Groups")
            checklistFile.addGroups(contentsOf: removedGroups)
        }
    }
    
    func removeGroups(contentsOf: [Group])
    {
        groups.removeAll(where: { group in
            contentsOf.contains(where: {groupToRemove in
                groupToRemove.id == group.id
            })
        })

        undoManager?.setActionName("Remove Groups")
        undoManager?.registerUndo(withTarget: self)
        { checklistFile in
            checklistFile.undoManager?.setActionName("Remove Groups")
            checklistFile.addGroups(contentsOf: contentsOf)
        }
    }
    
    func removeGroup(_ group: Group)
    {
        groups.removeAll(where: { $0.id == group.id })

        undoManager?.setActionName("Remove Group")
        undoManager?.registerUndo(withTarget: self)
        { checklistFile in
            checklistFile.undoManager?.setActionName("Remove Group")
            checklistFile.addGroup(group)
        }
    }
    
    func addGroups(contentsOf: [Group])
    {
        groups.append(contentsOf: contentsOf)

        undoManager?.setActionName("Add Groups")
        undoManager?.registerUndo(withTarget: self)
        { checklistFile in
            checklistFile.undoManager?.setActionName("Add Groups")
            checklistFile.removeGroups(contentsOf: contentsOf)
        }
    }
    
    func addGroup(_ group: Group)
    {
        groups.append(group)

        undoManager?.setActionName("Add Group")
        undoManager?.registerUndo(withTarget: self)
        { checklistFile in
            checklistFile.undoManager?.setActionName("Add Group")
            checklistFile.removeGroup(group)
        }
    }
    
    func addGroup(_ group: Group, after: UUID?)
    {
        guard let after else
        {
            return
        }
        if let itemIndex = groups.firstIndex(where: { $0.id == after })
        {
            groups.insert(group, at: itemIndex + 1)

            undoManager?.setActionName("Add Group")
            undoManager?.registerUndo(withTarget: self)
            { checklistFile in
                checklistFile.undoManager?.setActionName("Add Group")
                checklistFile.removeGroup(group)
            }
        }
    }
    
    func duplicateGroup(_ id: UUID?)
    {
        if let id, let groupToDuplicate = getGroup(id)
        {
            let duplicate = groupToDuplicate.duplicate()
            addGroup(duplicate, after: id)
        }
    }
    
    func setDefaultGroup(_ id: UUID)
    {
        for group in groups 
        {
            if group.id == id
            {
                group.isDefault = true
            }
            else
            {
                group.isDefault = false
            }
        }
        self.objectWillChange.send()
    }
    
    func setDefaultGroup(byIndex: Int)
    {
        if byIndex < groups.count - 1
        {
            groups[byIndex].isDefault = true
            
            self.objectWillChange.send()
        }
    }
    
    func setDefaultChecklist(byIndex: Int)
    {
        if let group = getDefaultGroup()
        {
            group.setDefaultChecklist(byIndex: byIndex)
            self.objectWillChange.send()
        }
    }
    
    func getGroup(_ id: UUID) -> Group?
    {
        return groups.first(where: { $0.id == id })
    }
    
    func getDefaultGroupIndex() -> Int
    {
        if let index = groups.firstIndex(where: { $0.isDefault })
        {
            return index
        }
        return 0
    }
    
    func getDefaultGroup() -> Group?
    {
        return groups.first(where: { $0.isDefault })
    }
    
    func getDefaultGroupName() -> String
    {
        if let group = getDefaultGroup()
        {
            return group.name
        }
        
        return "None"
    }
    
    func getDefaultChecklistIndex() -> Int
    {
        if let group = getDefaultGroup()
        {
            return group.getDefaultChecklistIndex()
        }
        return 0
    }
    
    func getDefaultChecklist() -> Checklist?
    {
        return getDefaultGroup()?.getDefaultChecklist()
    }
    
    func getDefaultChecklistName() -> String
    {
        if let group = getDefaultGroup()
        {
            if let checklist = group.getDefaultChecklist()
            {
                return checklist.name
            }
        }
        return "None"
    }
}
