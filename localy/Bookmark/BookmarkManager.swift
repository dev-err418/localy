//
//  BookmarkManager.swift
//  lookup
//
//  Created by arthur on 14/05/2024.
//

import SwiftUI

class BookmarkManager {
    static let manager = BookmarkManager()
    
    func saveBookmark(for url: URL) {
        
        guard let bookmarkDic = self.getBookmarkData(url: url),
              let bookmarkURL = getBookmarkURL() else{
            print("Error getting data or bookmarkURL")
            return
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: bookmarkDic, requiringSecureCoding: false)
            try data.write(to: bookmarkURL)
            print("Did save data to url")
        }
        catch {
            print("Couldn't save bookmarks")
        }
    }
    
    // Load bookmarks when your app launch for first time
    func loadBookmarks() {
        
        guard let url = self.getBookmarkURL() else {
            return
        }
        
        if self.fileExists(url) {
            do {
                let fileData = try Data(contentsOf: url)
                let unarchiver: NSKeyedUnarchiver = try NSKeyedUnarchiver(forReadingFrom: fileData)
                unarchiver.requiresSecureCoding = false;
                if let fileBookmarks = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! [URL: Data]? {
                    for bookmark in fileBookmarks {
                        self.restoreBookmark(key: bookmark.key, value: bookmark.value)
                    }
                }
            }
            catch {
                print ("Couldn't load bookmarks")
            }
        }
        
        /*if self.fileExists(url) {
            do {
                let fileData = try Data(contentsOf: url)
                if let fileBookmarks = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(fileData) as! [URL: Data]? {
                    for bookmark in fileBookmarks {
                        self.restoreBookmark(key: bookmark.key, value: bookmark.value)
                    }
                }                                
            }
            catch {
                print ("Couldn't load bookmarks")
            }
        }*/ else {
            print("file do not exists")
        }
    }
    
    private func restoreBookmark(key: URL, value: Data){
        let restoredUrl: URL?
        var isStale = false
        
        Swift.print ("Restoring \(key)")
        do {
            // https://stackoverflow.com/questions/76810173/swiftui-how-to-save-url-bookmarks-with-security-scope
            // if lots of urls, add this param : .withoutImplicitSecurityScope
            restoredUrl = try URL.init(resolvingBookmarkData: value, options: NSURL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        }
        catch {
            Swift.print ("Error restoring bookmarks")
            restoredUrl = nil
        }
        
        if let url = restoredUrl {
            if isStale {
                Swift.print ("URL is stale")
            }
            else {
                if !url.startAccessingSecurityScopedResource() {
                    Swift.print ("Couldn't access: \(url.path)")
                }
            }
        }
    }
    
    private func getBookmarkData(url: URL) -> [URL: Data]? {
        let data = try? url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        if let data = data {
            print(data)
            return [url: data]
        }
        return nil
    }
    
    private func getBookmarkURL() -> URL? {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let appSupportURL = urls.last{
            let url = appSupportURL.appendingPathComponent("Bookmarks.dict")
            return url
        }
        return nil
    }
    
    private func fileExists(_ url: URL) -> Bool {
        print(url)
        var isDir = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        
        return exists
    }
}
