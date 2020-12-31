
import Foundation

var standardError = FileHandle.standardError

if CommandLine.arguments.count > 2 {
    print("Usage: SwiftLox [script]", to: &standardError)
    exit(64)
} else if CommandLine.arguments.count == 2 {
    let path = CommandLine.arguments[1]
    SwiftLox.runFile(atPath: path)
    if SwiftLox.hadError {
        exit(65)
    }
} else {
    SwiftLox.runPrompt()
}

