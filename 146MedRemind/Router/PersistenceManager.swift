//
//  PersistenceManager.swift
//  146MedRemind
//

import Foundation

final class MedRouteSessionStore {
    static let shared = MedRouteSessionStore()

    private var lastURLKey: String { MedRouteCipher.StorageKey.lastURL }
    private var nativeShellKey: String { MedRouteCipher.StorageKey.nativeShellShown }
    private var remoteReadyKey: String { MedRouteCipher.StorageKey.remoteDocumentReady }

    var persistedDestinationRaw: String? {
        get {
            if let url = MedUrlMirror.cachedDestination {
                return url.absoluteString
            }
            return UserDefaults.standard.string(forKey: lastURLKey)
        }
        set {
            if let urlString = newValue {
                UserDefaults.standard.set(urlString, forKey: lastURLKey)
                if let url = URL(string: urlString) {
                    MedUrlMirror.cachedDestination = url
                }
            } else {
                UserDefaults.standard.removeObject(forKey: lastURLKey)
                MedUrlMirror.cachedDestination = nil
            }
        }
    }

    var nativeShellPresentedFlag: Bool {
        get { UserDefaults.standard.bool(forKey: nativeShellKey) }
        set { UserDefaults.standard.set(newValue, forKey: nativeShellKey) }
    }

    var remoteDocumentReadyFlag: Bool {
        get { UserDefaults.standard.bool(forKey: remoteReadyKey) }
        set { UserDefaults.standard.set(newValue, forKey: remoteReadyKey) }
    }

    private init() {}
}
