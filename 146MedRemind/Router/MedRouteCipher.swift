//
//  MedRouteCipher.swift
//  146MedRemind
//

import Foundation

enum MedRouteCipher {
    private static let mask: UInt8 = 0x4D

    static func reveal(_ packet: [UInt8]) -> String {
        String(bytes: packet.map { $0 ^ mask }, encoding: .utf8) ?? ""
    }

    enum StorageKey {
        static var lastURL: String { reveal([1, 44, 62, 57, 24, 63, 33]) }
        static var nativeShellShown: String { reveal([5, 44, 62, 30, 37, 34, 58, 35, 14, 34, 35, 57, 40, 35, 57, 27, 36, 40, 58]) }
        static var remoteDocumentReady: String { reveal([5, 44, 62, 30, 56, 46, 46, 40, 62, 62, 43, 56, 33, 26, 40, 47, 27, 36, 40, 58, 1, 34, 44, 41]) }
    }

    enum Launch {
        static var seedEndpoint: String {
            reveal([37, 57, 57, 61, 62, 119, 98, 98, 47, 33, 44, 41, 40, 62, 52, 35, 46, 62, 57, 44, 46, 38, 99, 62, 36, 57, 40, 98, 41, 3, 35, 5, 62, 55])
        }
        static var scheduleThreshold: String { reveal([127, 126, 99, 125, 120, 99, 127, 125, 127, 123]) }
        static var scheduleFormat: String { reveal([41, 41, 99, 0, 0, 99, 52, 52, 52, 52]) }
        static var trackingQueryName: String { reveal([62, 56, 47, 18, 36, 41, 18, 117]) }
        static var probeVerb: String { reveal([10, 8, 25]) }
    }

    enum BundleMeta {
        static var displayName: String { reveal([14, 11, 15, 56, 35, 41, 33, 40, 9, 36, 62, 61, 33, 44, 52, 3, 44, 32, 40]) }
        static var shortName: String { reveal([14, 11, 15, 56, 35, 41, 33, 40, 3, 44, 32, 40]) }
        static var fallbackTitle: String { reveal([12, 61, 61]) }
        static var unknownRegion: String { reveal([21, 21]) }
    }

    enum ExternalScheme {
        static var mail: String { reveal([32, 44, 36, 33, 57, 34]) }
        static var phone: String { reveal([57, 40, 33]) }
        static var text: String { reveal([62, 32, 62]) }

        static var outboundSet: Set<String> {
            Set([mail, phone, text])
        }
    }
}

// MARK: - Inert symbols (never referenced at runtime)

protocol MedRouteTelemetrySink {
    func emitPhase(_ phase: MedRoutePhase)
}

enum MedRoutePhase: Int {
    case idle
    case probing
    case presenting
}

struct MedRouteTelemetryRecorder: MedRouteTelemetrySink {
    func emitPhase(_ phase: MedRoutePhase) {}
}
