//
//  Summary.swift
//  XCTestHTMLReport
//
//  Created by Titouan van Belle on 21.07.17.
//  Copyright © 2017 Tito. All rights reserved.
//

import Foundation
import XCResultKit

struct TestSummary: HTML
{
    var uuid: String
    var testName: String
    var tests: [Test]
    var testFilter : String? = nil
    var status: Status {
        var currentTests = tests
        
        if let filter = testFilter {
            currentTests = currentTests.filter{ $0.name == filter }
        }
        
        var status: Status = .unknown

        if currentTests.count == 0 {
            return .success
        }

        status = currentTests.reduce(.unknown, { (accumulator: Status, test: Test) -> Status in
            if accumulator == .unknown {
                return test.status
            }

            if test.status == .failure {
                return .failure
            }

            if test.status == .success {
                return accumulator == .failure ? .failure : .success
            }

            return .unknown
        })

        currentTests = currentTests.reduce([], { (accumulator: [Test], test: Test) -> [Test] in
            if let subTests = test.subTests {
                return accumulator + subTests
            }

            return accumulator
        })

        return status
    }

    init(summary: ActionTestableSummary, file: ResultFile) {
        self.uuid = UUID().uuidString
        self.testName = summary.targetName ?? ""
        self.tests = summary.tests.map { Test(group: $0, file: file) }
    }

    // PRAGMA MARK: - HTML

    var htmlTemplate = HTMLTemplates.testSummary

    var htmlPlaceholderValues: [String: String] {
        
        var testsToUse = tests
        if let filter = testFilter {
            testsToUse = tests.filter{ $0.name == filter }
        }

        return [
            "UUID": uuid,
            "TESTS": testsToUse.reduce("", { (accumulator: String, test: Test) -> String in
                return accumulator + test.html
            })
        ]
    }
}

extension Test {
    func allTestSummaries() -> [Test] {
        if self.objectClass == .testSummary {
            return [self]
        }
        return subTests.flatMap { $0.allTestSummaries() }
    }
}
