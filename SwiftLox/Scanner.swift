
import Foundation

class Scanner {
    private let source: String
    private var tokens: [Token] = []

    private lazy var startIndex = source.startIndex
    private lazy var currentIndex = source.startIndex
    private var line = 1

    private var isAtEnd: Bool {
        currentIndex >= source.endIndex
    }

    private let keywords: [String : Token.Kind] = [
        "and": .and,
        "class": .class,
        "else": .else,
        "false": .false,
        "for": .for,
        "fun": .fun,
        "if": .if,
        "nil": .nil,
        "or": .or,
        "print": .print,
        "return": .return,
        "super": .super,
        "this": .this,
        "true": .true,
        "var": .var,
        "while": .while
    ]

    init(source: String) {
        self.source = source
    }

    func scanTokens() -> [Token] {
        while !isAtEnd {
            startIndex = currentIndex
            scanToken()
        }
        tokens.append(Token(kind: .eof, lexeme: "", value: nil, line: line))
        return tokens
    }

    private func scanToken() {
        switch advance() {
        case "(": addToken(.leftParen)
        case ")": addToken(.rightParen)
        case "{": addToken(.leftBrace)
        case "}": addToken(.rightBrace)
        case ",": addToken(.comma)
        case ".": addToken(.dot)
        case "-": addToken(.minus)
        case "+": addToken(.plus)
        case ";": addToken(.semicolon)
        case "*": addToken(.star)
        case "!": addToken(match("=") ? .bangEqual : .bang)
        case "=": addToken(match("=") ? .equalEqual : .equal)
        case "<": addToken(match("=") ? .lessEqual : .less)
        case ">": addToken(match("=") ? .greaterEqual : .greater)
        case "/":
            if match("/") {
                while peek() != "\n" && !isAtEnd { advance() }
            } else {
                addToken(.slash)
            }
        case " ", "\t", "\r": break
        case "\"": scanString()
        case "0"..."9": scanNumber()
        case "a"..."z", "A"..."Z", "_": scanIdentifier()
        case "\n": line += 1
        default: SwiftLox.reportError(onLine: line, withMessage: "Unexpected character.")
        }
    }

    private func scanIdentifier() {
        while peek().isAlphaNumeric { advance() }
        let kind = keywords[String(source[startIndex..<currentIndex])] ?? .identifier
        addToken(kind)
    }

    private func scanNumber() {
        while peek().isDigit { advance() }
        if peek() == "." && peekNext().isDigit {
            advance()
            while peek().isDigit { advance() }
        }
        let value = Double(source[startIndex..<currentIndex])!
        addToken(.number, withValue: value)
    }

    private func scanString() {
        while peek() != "\"" && !isAtEnd {
            if peek() == "\n" { line += 1 }
            advance()
        }

        if isAtEnd {
            SwiftLox.reportError(onLine: line, withMessage: "Unterminated string.")
            return
        }

        advance()

        let stringStartIndex = source.index(after: startIndex)
        let stringEndIndex = source.index(before: currentIndex)
        let value = String(source[stringStartIndex..<stringEndIndex])
        addToken(.string, withValue: value)
    }

    @discardableResult private func advance() -> Character {
        let character = source[currentIndex]
        currentIndex = source.index(after: currentIndex)
        return character
    }

    private func match(_ expected: Character) -> Bool {
        if isAtEnd { return false }
        if source[currentIndex] != expected { return false }
        advance()
        return true
    }

    private func peek() -> Character {
        if isAtEnd { return "\0" }
        return source[currentIndex]
    }

    private func peekNext() -> Character {
        let nextIndex = source.index(after: currentIndex)
        if nextIndex >= source.endIndex { return "\0" }
        return source[nextIndex]
    }

    private func addToken(_ kind: Token.Kind, withValue value: Any? = nil) {
        let lexeme = source[startIndex..<currentIndex]
        let token = Token(kind: kind, lexeme: lexeme, value: value, line: line)
        tokens.append(token)
    }
}
