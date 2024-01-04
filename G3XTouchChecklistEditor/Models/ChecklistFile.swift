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
    static let checklistDocument = UTType(exportedAs: "com.garmin.g3x.checklist")
}

class ChecklistFile: FileDocument, ObservableObject, Identifiable
{
    static var readableContentTypes: [UTType] = [.checklistDocument]
    
    static let footer = "END"
    static let separator:[UInt8] = [0x0D, 0x0A]
    
    var undoManager: UndoManager?
    @Published var id = UUID()
    @Published var name = ""
    @Published var makeAndModel = ""
    @Published var aircraftInfo = ""
    @Published var manufacturerID = ""
    @Published var copyright = ""
    var magicHeader1:[UInt8] = [0xF0, 0xF0, 0xF0, 0xF0]
    var magicHeader2:[UInt8] = [0x00, 0x01, 0x00, 0x00]
    @Published var groups:[Group] = []
    @Published var defaultGroup:UInt8 = 0
    @Published var defaultChecklist:UInt8 = 0
    // Don't like this UI data here but these will stay here until I come up with a better way
    @Published var isExpanded = false

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
        groups = [Group()]
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
    }
    
    func exportData() throws -> Data
    {
        var data = Data()
        
        data.append(contentsOf: magicHeader1)
        // TODO Need to get the default group and checklist in here
        data.append(contentsOf: magicHeader2)
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: name.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: makeAndModel.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: aircraftInfo.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: manufacturerID.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        data.append(contentsOf: copyright.data(using: .ascii)!)
        data.append(contentsOf: ChecklistFile.separator)
        for group in groups
        {
            group.exportData(&data)
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
        
        defaultGroup = byte3!
        defaultChecklist = byte4!
        
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
}

