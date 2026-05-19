//
//  MedAppExternalLink.swift
//  146MedRemind
//

import Foundation

/// Legal and marketing URLs. Replace placeholders with your production links.
enum MedAppExternalLink: String {
    case privacyPolicy = "https://www.termsfeed.com/live/9019a746-08b7-4f97-98d7-b0b5da332dc0"
    case termsOfUse = "https://www.termsfeed.com/live/607e2411-f42f-4152-bf88-2047fc4ba6c7"

    var url: URL? {
        URL(string: rawValue)
    }
}
