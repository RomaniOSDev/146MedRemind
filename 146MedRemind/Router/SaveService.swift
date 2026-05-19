//
//  SaveService.swift
//  146MedRemind
//

import Foundation

struct MedUrlMirror {

    static var cachedDestination: URL? {
        get { UserDefaults.standard.url(forKey: MedRouteCipher.StorageKey.lastURL) }
        set { UserDefaults.standard.set(newValue, forKey: MedRouteCipher.StorageKey.lastURL) }
    }
}
