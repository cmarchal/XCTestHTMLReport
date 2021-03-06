//
//  TestScreenshotFlow.swift
//  XCTestHTMLReport
//
//  Created by Alistair Leszkiewicz on 11/10/18.
//  Copyright © 2018 Tito. All rights reserved.
//
import Foundation

struct TestAttachmentFlow
{
    var files: [FileAttachment]
    var screenshots: [ScreenshotAttachment]

    init?(activities: [Activity]?) {
        guard let activities = activities else {
            return nil
        }
        
        let anyFiles = activities.trueForAny { !$0.screenshotAttachments.isEmpty }
        guard anyFiles else {
            return nil
        }
        files = activities.flatMap { $0.fileAttachments.map { FileAttachment(attachment: $0) } }
        
        let anyScreenshots = activities.trueForAny { !$0.screenshotAttachments.isEmpty }
        guard anyScreenshots else {
            return nil
        }
        screenshots = activities.flatMap { $0.screenshotAttachments.map { ScreenshotAttachment(attachment: $0) } }
    }
    
    func html() -> String {
        return files.accumulateHTMLAsString + "\n" + screenshots.accumulateHTMLAsString
    }
    
}

fileprivate extension Sequence {
    // Determines whether any element in the Array matches the conditions defined by the specified predicate.
    func trueForAny(_ predicate: (Element) -> Bool) -> Bool {
        return first(where: predicate) != nil
    }
}

fileprivate extension Activity {
    
    var fileAttachments: [Attachment] {
        return attachments.compactMap({ $0 }).filter { !$0.isScreenshot }
            + subFileAttachments
    }
    
    var subFileAttachments: [Attachment] {
        return subActivities.compactMap({ $0 }).flatMap({ $0.fileAttachments })
    }

    var screenshotAttachments: [Attachment] {
        return attachments.compactMap({ $0 }).filter { $0.isScreenshot }
            + subScreenshotAttachments
    }
    
    var subScreenshotAttachments: [Attachment] {
        return subActivities.compactMap({ $0 }).flatMap({ $0.screenshotAttachments })
    }
}


struct FileAttachment: HTML {
    let attachment: Attachment
    
    static let file = """
    <p class="attachment list-item">
        <span class="icon left text-icon"></span>
        [[FILENAME]]
        <span class="icon preview-icon" data="[[PATH]]" onclick="showText('[[PATH]]')"></span>
    </p>
    """
    
    var htmlTemplate: String {
        return FileAttachment.file
    }
    
    var htmlPlaceholderValues: [String: String] {
        return [
            "PATH": attachment.path,
            "FILENAME": attachment.filename
        ]
    }
}

struct ScreenshotAttachment: HTML {
    let attachment: Attachment
    
    static let screenshotWithStep = """
  <div style=\"position:relative;display:inline-block;\">
      <img class=\"preview-screenshot\" src=\"[[PATH]]\" id=\"screenshot-[[FILENAME]]\" onclick=\"showScreenshot('[[FILENAME]]', '[[STEP]]')\"/>
      <b class=\"screenshot-step\">STEP [[STEP]]</b>
  </div>
  """

    static let screenshotWithoutStep = """
  <img class=\"preview-screenshot\" src=\"[[PATH]]\" id=\"screenshot-[[FILENAME]]\" onclick=\"showScreenshot('[[FILENAME]]', '[[STEP]]')\"/>
  """

    
    var htmlTemplate: String {
        if attachment.step != nil {
            return ScreenshotAttachment.screenshotWithStep
        } else {
            return ScreenshotAttachment.screenshotWithoutStep
        }
    }
    
    var htmlPlaceholderValues: [String: String] {
        
        if let step = attachment.step {
            return [
                "PATH": attachment.path,
                "FILENAME": attachment.filename,
                "STEP": step
            ]
        } else {
            return [
                "PATH": attachment.path,
                "FILENAME": attachment.filename
            ]
        }
    }
}

