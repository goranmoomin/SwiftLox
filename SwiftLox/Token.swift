
import Foundation

struct Token {
    enum Kind {
        case leftParen, rightParen, leftBrace, rightBrace, comma, dot, minus, plus, semicolon, slash, star
        case bang, bangEqual, equal, equalEqual, greater, greaterEqual, less, lessEqual
        case identifier, string, number
        case and, `class`, `else`, `false`, fun, `for`, `if`, `nil`, `or`, print, `return`, `super`, this, `true`, `var`, `while`
        case eof
    }

    let kind: Kind
    let lexeme: Substring
    let value: Any?
    let line: Int
}
