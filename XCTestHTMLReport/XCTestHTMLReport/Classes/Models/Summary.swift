//
//  Summary.swift
//  XCTestHTMLReport
//
//  Created by Titouan van Belle on 21.07.17.
//  Copyright © 2017 Tito. All rights reserved.
//

import Foundation

struct Summary
{
    private let filename = "action_TestSummaries.plist"

    var runs = [Run]()
    
    var totalNumberOfPassedTests = 0
    var totalNumberOfFailedTests = 0
    var totalNumberOfTests = 0

    init(roots: [String])
    {
        let indexHTMLRoot = roots[0]
        for root in roots {
            Logger.step("Parsing Test Summaries")
            let enumerator = FileManager.default.enumerator(atPath: root)

            guard enumerator != nil else {
                Logger.error("Failed to create enumerator for path \(root)")
                exit(EXIT_FAILURE)
            }

            let paths = enumerator?.allObjects as! [String]

            Logger.substep("Searching for \(filename) in \(root)")
            let plistPath = paths.filter { $0.contains("action_TestSummaries.plist") }

            if plistPath.count == 0 {
                Logger.error("Failed to find action_TestSummaries.plist in \(root)")
                exit(EXIT_FAILURE)
            }

            for path in plistPath {
                let run = Run(root: root, path: path, indexHTMLRoot: indexHTMLRoot)
                runs.append(run)
                totalNumberOfPassedTests += run.numberOfPassedTests
                totalNumberOfFailedTests += run.numberOfFailedTests
                totalNumberOfTests += run.numberOfTests
            }
        }
        
        Logger.step("Summary result")
        Logger.substep("Total number of tests: \(totalNumberOfTests)")
        Logger.substep("Total number of passed tests: \(totalNumberOfPassedTests)")
        Logger.substep("Total number of failed tests: \(totalNumberOfFailedTests)")
    }
}

extension Summary: HTML
{
    var htmlTemplate: String {
        return HTMLTemplates.index
    }

    var htmlPlaceholderValues: [String: String] {
        return [
            "DEVICES": runs.map { $0.runDestination.html }.joined(),
            "RESULT_CLASS": runs.reduce(true, { (accumulator: Bool, run: Run) -> Bool in
                return accumulator && run.status == .success
            }) ? "success" : "failure",
            "RUNS": runs.map { $0.html }.joined()
        ]
    }
}

extension Summary: JUnitRepresentable
{
    var junit: JUnitReport {
        return JUnitReport(summary: self)
    }
}
