//
//  main.swift
//  XCTestHTMLReport
//
//  Created by Titouan van Belle on 21.07.17.
//  Copyright © 2017 Tito. All rights reserved.
//

import Foundation

var version = "1.6.1"

print("XCTestHTMLReport \(version)")

var command = Command()
var help = BlockArgument("h", "", required: false, helpMessage: "Print usage and available options") {
    print(command.usage)
    exit(EXIT_SUCCESS)
}
var verbose = BlockArgument("v", "", required: false, helpMessage: "Provide additional logs") {
    Logger.verbose = true
}
var junitEnabled = false
var junit = BlockArgument("j", "junit", required: false, helpMessage: "Provide JUnit XML output") {
    junitEnabled = true
}
var result = ValueArgument(.path, "r", "resultBundlePath", required: true, allowsMultiple: true, helpMessage: "Path to a result bundle (allows multiple)")

command.arguments = [help, verbose, junit, result]

if !command.isValid {
    print(command.usage)
    exit(EXIT_FAILURE)
}

let summary = Summary(roots: result.values)

Logger.step("Building HTML..")
let html = summary.html

//Cleaning HTML file from empty divs and spans
let regex = try! NSRegularExpression(pattern: "  <div id=\"(.*)\" class=\"(.*)\">\n      \n  </div>", options: NSRegularExpression.Options.caseInsensitive)
let range = NSMakeRange(0, html.count)
var cleanedHtml = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")

cleanedHtml = cleanedHtml.replacingOccurrences(of: "    <span class=\"icon paperclip-icon\" style=\"display: none\"></span>\n", with: "")

do {
    let path = "\(result.values.first!)/index.html"
    Logger.substep("Writing report to \(path)")

    try cleanedHtml.write(toFile: path, atomically: false, encoding: .utf8)
    Logger.success("\nReport successfully created at \(path)")
}
catch let e {
    Logger.error("An error has occured while creating the report. Error: \(e)")
}

if junitEnabled {
    Logger.step("Building JUnit..")
    let junitXml = summary.junit.xmlString
    do {
        let path = "\(result.values.first!)/report.junit"
        Logger.substep("Writing JUnit report to \(path)")

        try junitXml.write(toFile: path, atomically: false, encoding: .utf8)
        Logger.success("\nJUnit report successfully created at \(path)")
    }
    catch let e {
        Logger.error("An error has occured while creating the JUnit report. Error: \(e)")
    }
}

exit(EXIT_SUCCESS)
