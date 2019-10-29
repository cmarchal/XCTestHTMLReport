import Darwin
import Foundation

var version = "2.0.0"

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
var generateReportForEachTestEnabled = false
var generateReportForEachTest = BlockArgument("a", "generateReportForEachTest", required: false, helpMessage: "Generate one report for each test in the report in addition to the global report") {
    generateReportForEachTestEnabled = true
}

command.arguments = [help, verbose, junit, result, generateReportForEachTest]

if !command.isValid {
    print(command.usage)
    exit(EXIT_FAILURE)
}

let summary = Summary(resultPaths: result.values)

Logger.step("Building HTML..")
let html = summary.html

//Cleaning HTML from empty divs and spans
let regex = try! NSRegularExpression(pattern: "  <div id=\"(.*)\" class=\"(.*)\">\n      \n  </div>", options: NSRegularExpression.Options.caseInsensitive)
let range = NSMakeRange(0, html.count)
var cleanedHtml = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")

cleanedHtml = cleanedHtml.replacingOccurrences(of: "    <span class=\"icon paperclip-icon\" style=\"display: none\"></span>\n", with: "")

do {
    let path = result.values.first!
        .dropLastPathComponent()
        .addPathComponent("index.html")
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


if generateReportForEachTestEnabled {
    for run in summary.runs {
        for test in run.allTests {

            var tmpTest: Test? = test

            while tmpTest?.parent != nil {
                tmpTest?.parent?.testFilter = tmpTest?.name
                tmpTest = tmpTest?.parent
            }
            var tmpRun = run
            tmpRun.testSummaries = tmpRun.testSummaries.filter { $0.tests.contains(tmpTest!) }

            for index in 0..<tmpRun.testSummaries.count {
                tmpRun.testSummaries[index].testFilter = tmpTest?.name
            }

            let newSummary = Summary(runs: [tmpRun])
            do {
                let directoryName = test.name.replacingOccurrences(of: "(", with: "")
                                             .replacingOccurrences(of: ")", with: "")
                do {
                    try FileManager.default.createDirectory(atPath: "\(result.values.first!)/\(directoryName)/Attachments", withIntermediateDirectories: true, attributes: nil)
                } catch {
                    Logger.error("An error has occured while creating the report. Error: \(error)")
                }

                let path = "\(result.values.first!)/\(directoryName)/index.html"
                Logger.substep("Copying attachments to \(path)")

                for screenshot in test.testAttachmentFlow?.screenshots ?? [] {
                    do {
                        try
                            FileManager.default.moveItem(atPath: "\(result.values.first!)/\(screenshot.attachment.path)/../Attachments/\(screenshot.attachment.filename)",
                                toPath: "\(result.values.first!)/\(directoryName)/Attachments/\(screenshot.attachment.filename)")
                    } catch {
                        Logger.error("An error has occured while moving attachments. Error: \(error)")
                    }
                }
                for file in test.testAttachmentFlow?.files ?? [] {
                    do {
                        try
                            FileManager.default.moveItem(atPath: "\(result.values.first!)/\(file.attachment.path)/../Attachments/\(file.attachment.filename)",
                                toPath: "\(result.values.first!)/\(directoryName)/Attachments/\(file.attachment.filename)")
                    } catch {
                        Logger.error("An error has occured while moving attachments. Error: \(error)")
                    }
                }

                Logger.substep("Writing report to \(path)")

                //First to hide unnecessary info
                //Second to change attachments path with new one
                try newSummary.html.replacingOccurrences(of: "class=\"tests-header\"",
                                                         with: "class=\"tests-header\" hidden")
                    .replacingOccurrences(of: "\(test.testAttachmentFlow?.files.first?.attachment.path ?? "")/", with: "")
                    .write(toFile: path, atomically: false, encoding: .utf8)
                Logger.success("\nReport successfully created at \(path)")

            }
            catch let e {
                Logger.error("An error has occured while creating the report. Error: \(e)")
            }
        }
    }
}


exit(EXIT_SUCCESS)
