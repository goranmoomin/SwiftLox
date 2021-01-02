
import Foundation

class Parser {
    struct ParseError: Error {}

    private var tokens: [Token]
    private var currentIndex: Int = 0

    private var isAtEnd: Bool {
        peek().kind == .eof
    }

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func parseExpression() throws -> Expression {
        try parseEquality()
    }

    private func parseEquality() throws -> Expression {
        var expression = try parseComparison()
        while match(.bangEqual, .equalEqual) {
            let `operator` = previous()
            let right = try parseComparison()
            expression = .binary(left: expression, operator: `operator`, right: right)
        }
        return expression
    }

    private func parseComparison() throws -> Expression {
        var expression = try parseTerm()
        while match(.greater, .greaterEqual, .less, .lessEqual) {
            let `operator` = previous()
            let right = try parseComparison()
            expression = .binary(left: expression, operator: `operator`, right: right)
        }
        return expression
    }

    private func parseTerm() throws -> Expression {
        var expression = try parseFactor()
        while match(.minus, .plus) {
            let `operator` = previous()
            let right = try parseFactor()
            expression = .binary(left: expression, operator: `operator`, right: right)
        }
        return expression
    }

    private func parseFactor() throws -> Expression {
        var expression = try parseUnary()
        while match(.slash, .star) {
            let `operator` = previous()
            let right = try parseUnary()
            expression = .binary(left: expression, operator: `operator`, right: right)
        }
        return expression
    }

    private func parseUnary() throws -> Expression {
        if match(.bang, .minus) {
            let `operator` = previous()
            let right = try parseUnary()
            return .unary(operator: `operator`, right: right)
        }
        return try parsePrimary()
    }

    private func parsePrimary() throws -> Expression {
        if match(.true) { return .literal(value: true) }
        if match(.false) { return .literal(value: false) }
        if match(.nil) { return .literal(value: nil) }
        if match(.number, .string) {
            return .literal(value: previous().value)
        }
        if match(.leftParen) {
            let expression = try parseExpression()
            try consume(.rightParen, withMessage: "Expect ')' after expression.")
            return .grouping(expression: expression)
        }
        reportError(on: peek(), withMessage: "Expect expression.")
        throw ParseError()
    }

    private func match(_ kinds: Token.Kind...) -> Bool {
        if kinds.contains(peek().kind) {
            advance()
            return true
        }
        return false
    }

    private func consume(_ kind: Token.Kind, withMessage message: String) throws {
        if check(kind) {
            advance()
            return
        }
        reportError(on: peek(), withMessage: message)
        throw ParseError()
    }

    private func check(_ kind: Token.Kind) -> Bool {
        peek().kind == kind
    }

    private func reportError(on token: Token, withMessage message: String) {
        if token.kind == .eof {
            SwiftLox.reportError(onLine: token.line, atLocation: "end", withMessage: message)
        } else {
            SwiftLox.reportError(onLine: token.line, atLocation: "'\(token.lexeme)'", withMessage: message)
        }
    }

    private func synchronize() {
        advance()
        while !isAtEnd {
            if previous().kind == .semicolon { return }
            switch peek().kind {
            case .class, .fun, .var, .for, .if, .while, .print, .return: return
            default: break
            }
            advance()
        }
    }

    @discardableResult private func advance() -> Token {
        if !isAtEnd { currentIndex += 1 }
        return previous()
    }

    private func peek() -> Token {
        tokens[currentIndex]
    }

    private func previous() -> Token {
        tokens[currentIndex - 1]
    }
}
