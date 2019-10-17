//
//  Test.swift
//  XCTestHTMLReport
//
//  Created by Titouan van Belle on 21.07.17.
//  Copyright © 2017 Tito. All rights reserved.
//

import Foundation
import XCResultKit

enum Status: String {
    case unknown = ""
    case failure = "Failure"
    case success = "Success"

    var cssClass: String {
        switch self {
        case .failure:
            return "failed"
        case .success:
            return "succeeded"
        default:
            return ""
        }
    }
}

enum ObjectClass: String {
    case unknwown = ""
    case testableSummary = "IDESchemeActionTestableSummary"
    case testSummary = "IDESchemeActionTestSummary"
    case testSummaryGroup = "IDESchemeActionTestSummaryGroup"
    
    var cssClass: String {
        switch self {
        case .testSummary:
            return "test-summary"
        case .testSummaryGroup:
            return "test-summary-group"
        case .testableSummary:
            return "testable-summary"
        default:
            return ""
        }
    }
}


class Test: HTML, Equatable
{
    static func == (lhs: Test, rhs: Test) -> Bool {
        return lhs.name == rhs.name
    }
    
    let externalLinkIdentifier: String = "externalLink:"

    var uuid: String
    var identifier: String
    var duration: Double
    var name: String
    var subTests: [Test]?
    var filteredSubTests: [Test]? {
        get {
            if testFilter != nil {
                return subTests?.filter{ $0.name == testFilter }
            } else {
                return subTests
            }
        }
    }
    var parent: Test?
    var activities: [Activity]?
    var status: Status
    var objectClass: ObjectClass
    var testAttachmentFlow: TestAttachmentFlow?
    var externalLink: String {
        
        if let externalLinkActivity = activities?.first(where: { $0.title.starts(with: externalLinkIdentifier) }) {
            return externalLinkActivity.title.replacingOccurrences(of: externalLinkIdentifier, with: "")
        }
        return ""
    }
    
    var testFilter : String? = nil

    var allSubTests: [Test]? {
        guard subTests != nil else {
            return nil
        }

        return subTests!.compactMap({ (test) -> [Test]? in
            guard test.allSubTests != nil else {
                return [test]
            }
            
            if let filter = testFilter {
                return test.allSubTests?.filter { $0.name == filter }
            } else {
                return test.allSubTests
            }
        }).flatMap { $0 }
    }

    var amountSubTests: Int {
        if let subTests = filteredSubTests {
            let a = subTests.reduce(0) { $0 + $1.amountSubTests }
            return a == 0 ? subTests.count : a
        }

        return 0
    }

    init(screenshotsPath: String, group: ActionTestSummaryGroup, file: ResultFile, parent: Test? = nil) {
        self.uuid = NSUUID().uuidString
        self.identifier = group.identifier
        self.duration = group.duration
        self.name = group.name
        if group.subtests.isEmpty {
            self.subTests = group.subtestGroups.map { Test(group: $0, file: file) }
        } else {
            self.subTests = group.subtests.map { Test(metadata: $0, file: file) }
        }
        self.objectClass = .testSummaryGroup
        self.activities = []
        self.status = .unknown // ???: Usefull?
        testAttachmentFlow = TestAttachmentFlow(activities: activities)
        self.setParentToChildren()
    }
    
    init(screenshotsPath: String, metadata: ActionTestMetadata, file: ResultFile, parent: Test? = nil) {
        self.uuid = NSUUID().uuidString
        self.identifier = metadata.identifier
        self.duration = metadata.duration ?? 0
        self.name = metadata.name
        self.subTests = []
        self.status = Status(rawValue: metadata.testStatus) ?? .failure
        self.objectClass = .testSummary
        if let id = metadata.summaryRef?.id,
            let actionTestSummary = file.getActionTestSummary(id: id) {
            self.activities = actionTestSummary.activitySummaries.map {
                Activity(summary: $0, file: file, padding: 20)
            }
        } else {
            self.activities = []
        }
        testAttachmentFlow = TestAttachmentFlow(activities: activities)
        self.setParentToChildren()
    }

    
     func setParentToChildren() {
        
        if let subtests = subTests {
            for index in 0..<subtests.count {
                subTests![index].parent = self
            }
        }
    }

    // PRAGMA MARK: - HTML

    var htmlTemplate = HTMLTemplates.test

    var htmlPlaceholderValues: [String: String] {
        
        return [
            "UUID": uuid,
            "NAME": name + (amountSubTests > 0 ? " - \(amountSubTests) tests" : ""),
            "TIME": amountSubTests == 1 ? filteredSubTests!.first!.duration.timeString : (testFilter == nil ? duration.timeString : "-"),
            "SUB_TESTS": subTests.reduce("") { (accumulator: String, test: Test) -> String in
                return accumulator + test.html
            },
            "HAS_ACTIVITIES_CLASS": (activities == nil) ? "no-drop-down" : "",
            "ACTIVITIES": activities.reduce("") { (accumulator: String, activity: Activity) -> String in
                return accumulator + activity.html
            },
            "ICON_CLASS": status.cssClass,
            "ITEM_CLASS": objectClass.cssClass,
            "LIST_ITEM_CLASS": objectClass == .testSummary ? (status == .failure ? "list-item list-item-failed" : "list-item") : "",
            "ATTACHMENT_FLOW": testAttachmentFlow?.html() ?? "",
            "EXTERNAL_LINK": externalLink,
            "SHOULD_SHOW_EXTERNAL_LINK": externalLink.count > 0 ? "" : "display:none;"
        ]
    }
}
