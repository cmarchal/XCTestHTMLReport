//
//  Activity.swift
//  XCTestHTMLReport
//
//  Created by Titouan van Belle on 22.07.17.
//  Copyright © 2017 Tito. All rights reserved.
//

import Foundation

enum ActivityType: String {
    case unknwown = ""
    case intern = "com.apple.dt.xctest.activity-type.internal"
    case deleteAttachment = "com.apple.dt.xctest.activity-type.deletedAttachment"
    case assertionFailure = "com.apple.dt.xctest.activity-type.testAssertionFailure"
    case userCreated = "com.apple.dt.xctest.activity-type.userCreated"
    case attachementContainer = "com.apple.dt.xctest.activity-type.attachmentContainer"

    var cssClass: String {
        switch self {
        case .intern:
            return "activity-internal"
        case .deleteAttachment:
            return "activity-delete-attachment"
        case .assertionFailure:
            return "activity-assertion-failure"
        case .userCreated:
            return "activity-user-created"
        default:
            return ""
        }
    }
}

struct Activity: HTML
{
    let uuid: String
    let padding: Int
    let attachments: [Attachment]
    let startTime: TimeInterval?
    let finishTime: TimeInterval?
    var totalTime: TimeInterval {
        if let start = startTime, let finish = finishTime {
            return finish - start
        }

        return 0.0
    }
    var title: String
    var subActivities: [Activity]
    var type: ActivityType?
    var hasGlobalAttachment: Bool {
        let hasDirectAttachment = !attachments.isEmpty
        let subActivitesHaveAttachments = subActivities.reduce(false) { $0 || $1.hasGlobalAttachment }
        return hasDirectAttachment || subActivitesHaveAttachments
    }
    var hasFailingSubActivities: Bool {
		return subActivities.reduce(false) { $0 || $1.type == .assertionFailure || $1.hasFailingSubActivities }
    }
    var cssClasses: String {
        var cls = ""
        if let type = type {
            cls += type.cssClass

            if type == .userCreated && hasFailingSubActivities {
                cls += " activity-assertion-failure"
            }
        }

        return cls
    }
    
    init(screenshotsPath: String, dict: [String : Any], padding: Int) {
        self.uuid = summary.uuid
        self.startTime = summary.start?.timeIntervalSince1970 ?? 0
        self.finishTime = summary.finish?.timeIntervalSince1970 ?? 0
        self.title = summary.title
        self.subActivities = summary.subactivities.map {
            Activity(summary: $0, file: file, padding: padding + 10)
        }
        self.type = ActivityType(rawValue: summary.activityType)
        self.attachments = summary.attachments.map {
            Attachment(attachment: $0, file: file, padding: padding + 16).filter{ !$0.displayName.starts(with: "Debug description")}
        }
        self.padding = padding
    }
    
    var isStepRelative: Bool {
        return title.starts(with: "STEP")
    }

    // PRAGMA MARK: - HTML

    var htmlTemplate = HTMLTemplates.activity

    var htmlPlaceholderValues: [String: String] {
        return [
            "UUID": uuid,
            "TITLE": title.stringByEscapingXMLChars,
            "PAPER_CLIP_CLASS": hasGlobalAttachment ? "inline-block" : "none",
            "PADDING": (subActivities.isEmpty && attachments.isEmpty) ? String(padding + 18 + 52) : String(padding + 52),
            "TIME": totalTime.timeString,
            "ACTIVITY_TYPE_CLASS": cssClasses,
            "HAS_SUB-ACTIVITIES_CLASS": (subActivities.isEmpty && attachments.isEmpty) ? "no-drop-down" : "",
            "SUB_ACTIVITY": subActivities.reduce(""){ (accumulator: String, activity: Activity) -> String in
                return accumulator + activity.html
            },
            "ATTACHMENTS": attachments.reduce("") { (accumulator: String, attachment: Attachment) -> String in
                return accumulator + attachment.html
            },
        ]
    }
}
