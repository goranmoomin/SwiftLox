
import Foundation

class SwiftLox {
    static var hadError: Bool = false

    static func runFile(atPath path: String) {
        guard
            let data = FileManager.default.contents(atPath: path),
            let source = String(data: data, encoding: .utf8)
              else {
            hadError = true
            return
        }
        run(source)
    }

    static func runPrompt() {
        while true {
            print("> ", terminator: "")
            guard let line = readLine() else { break }
            run(line)
            hadError = false
        }
    }

    static func run(_ source: String) {
        let scanner = Scanner(source: source)
        let tokens = scanner.scanTokens()
        let parser = Parser(tokens: tokens)
        if hadError { return }
        if let expression = try? parser.parseExpression() {
            let printer = ASTPrinter()
            print(printer.printed(expression))
        }
    }

    static func reportError(onLine line: Int, atLocation location: String? = nil, withMessage message: String) {
        if let location = location {
            print("[line \(line)] Error at \(location): \(message)", to: &standardError)
        } else {
            print("[line \(line)] Error: \(message)", to: &standardError)
        }
        hadError = true
    }
}
