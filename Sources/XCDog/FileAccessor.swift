import Foundation

struct FileEntry {
    let url: URL
    let modificationDate: Date?
}

protocol FileAccessor {
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func entriesOfDirectory(at url: URL, options mask: FileManager.DirectoryEnumerationOptions) throws -> [FileEntry]
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws
    func removeItem(at URL: URL) throws
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any]
    func readFileContent(atPath path: String) throws -> String
}

class FileManagerAccessor: FileAccessor {

    private let fileManager: FileManager

    init(_ fileManager: FileManager) {
        self.fileManager = fileManager
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.copyItem(at: srcURL, to: dstURL)
    }

    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.moveItem(at: srcURL, to: dstURL)
    }

    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return fileManager.urls(for: directory, in: domainMask)
    }

    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        return fileManager.fileExists(atPath: path, isDirectory: isDirectory)
    }

    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }

    func entriesOfDirectory(at url: URL, options mask: FileManager.DirectoryEnumerationOptions) throws -> [FileEntry] {
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.contentModificationDateKey], options: mask)
        return contents.map({ url in
            return FileEntry(url: url.resolvingSymlinksInPath(), modificationDate: url.modificationDate)
        })
    }
    
    func removeItem(at URL: URL) throws {
        try fileManager.removeItem(at: URL)
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any] {
        return try fileManager.attributesOfItem(atPath: path)
    }

    func readFileContent(atPath path: String) throws -> String {
        try String(contentsOfFile: path)
    }
}
