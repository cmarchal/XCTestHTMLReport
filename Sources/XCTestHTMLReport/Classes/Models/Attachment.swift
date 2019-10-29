//
//  Attachment.swift
//  XCTestHTMLReport
//
//  Created by Titouan van Belle on 22.07.17.
//  Copyright © 2017 Tito. All rights reserved.
//

import Foundation
import XCResultKit

enum AttachmentType: String {
    case unknwown = ""
    case data = "public.data"
    case html = "public.html"
    case jpeg = "public.jpeg"
    case png = "public.png"
    case text = "public.plain-text"

    var cssClass: String {
        switch self {
        case .png, .jpeg:
            return "screenshot"
        case .text:
            return "text"
        default:
            return ""
        }
    }
}

enum AttachmentName: RawRepresentable {
    enum Constant: String {
        case kXCTAttachmentLegacyScreenImageData = "kXCTAttachmentLegacyScreenImageData"
    }
    
    case constant(Constant)
    case custom(String)
    
    var rawValue: String {
        switch self {
        case .constant(let constant):
            return constant.rawValue
        case .custom(let rawValue):
            return rawValue
        }
    }
    
    init(rawValue: String) {
        guard let constant = Constant(rawValue: rawValue) else {
            self = .custom(rawValue)
            return
        }
        
        self = .constant(constant)
    }
}

struct Attachment: HTML
{
    let padding: Int
    let filename: String
    var path: String
    let type: AttachmentType
    let name: AttachmentName?

    init(attachment: ActionTestAttachment, file: ResultFile, padding: Int = 0) {
        self.filename = attachment.filename ?? ""
        self.type = AttachmentType(rawValue: attachment.uniformTypeIdentifier) ?? .unknwown
        self.name = attachment.name.map(AttachmentName.init(rawValue:))
        if let id = attachment.payloadRef?.id,
            let url = file.exportPayload(id: id) {
            self.path = url.relativePath
        } else {
            self.path = ""
        }
        self.padding = padding
        //Updating file names in order to ease importing them in Matrix
        if FileManager.default.fileExists(atPath: file.url.relativePath + "/../" + path) {
            do {
                //Logger.success("\nNew path: \(path.addPathComponent("../\(filename)"))")
                let url = URL(fileURLWithPath: file.url.relativePath + "/../" + path)
                try FileManager.default.moveItem(at: url, to: url.appendingPathComponent("../\(filename)", isDirectory: false))
                path = path.addPathComponent("../\(filename)")
            } catch {
                Logger.error("\nFile not moved")
            }
        } else {
            Logger.error("\nFile at \(path) does not exist")
        }
    }

    var isScreenshot: Bool {
        switch type {
        case .png, .jpeg:
            return true
        default:
            return false
        }
    }


    var fallbackDisplayName: String {
        switch type {
        case .png, .jpeg:
            return "Screenshot"
        case .text, .html, .data:
            return "File"
        case .unknwown:
            return "Attachment"
        }
    }
    
    var displayName: String {
        switch name {
        case .some(.custom(let customName)):
            return customName
        default:
            return fallbackDisplayName
        }
    }

    var step: String? {

        let splitString = filename.components(separatedBy: "__step")
        if splitString.count > 1 {
            return splitString[1].components(separatedBy: "__")[0]
        }
        return nil
    }

    var isFailure: Bool {
        return filename.contains("Failure")
    }

    
    // PRAGMA MARK: - HTML

    var htmlTemplate: String {
        switch type {
        case .png, .jpeg:
            return HTMLTemplates.screenshot
        case .text, .html, .data:
            return HTMLTemplates.text
        case .unknwown:
            return ""
        }
    }

    var htmlPlaceholderValues: [String: String] {
        return [
            "PADDING": String(padding + 52),
            "PATH": path,
            "FILENAME": filename,
            "NAME": displayName
        ]
    }
}

