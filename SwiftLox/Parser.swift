
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

    func parse() -> [Statement] {
        var statements: [Statement] = []
        while !isAtEnd {
            if let statement = parseDeclaration() {
                statements.append(statement)
            }
        }
        return statements
    }

    private func parseDeclaration() -> Statement? {
        do {
            if match(.var) { return try parseVarDeclaration() }
            return try parseStatement()
        } catch {
            synchronize()
            return nil
        }
    }

    private func parseVarDeclaration() throws -> Statement {
        let name = try consume(.identifier, withMessage: "Expect variable name.")
        var initializer: Expression?
        if match(.equal) {
            initializer = try parseExpression()
        }
        try consume(.semicolon, withMessage: "Expect ';' after variable declaration.")
        return .var(name: name, initializer: initializer)
    }

    private func parseStatement() throws -> Statement {
        if match(.for) { return try parseForStatement() }
        if match(.if) { return try parseIfStatement() }
        if match(.print) { return try parsePrintStatement() }
        if match(.while) { return try parseWhileStatement() }
        if match(.leftBrace) { return try .block(statements: parseBlock()) }
        return try parseExpressionStatement()
    }

    private func parseForStatement() throws -> Statement {
        try consume(.leftParen, withMessage: "Expect '(' after 'for'.")
        let initializer: Statement?
        if match(.semicolon) {
            initializer = nil
        } else if match(.var) {
            initializer = try parseVarDeclaration()
        } else {
            initializer = try parseExpressionStatement()
        }
        var condition: Expression = .literal(value: true)
        if !check(.semicolon) {
            condition = try parseExpression()
        }
        try consume(.semicolon, withMessage: "Expect ';' after loop condition.")
        var increment: Expression?
        if !check(.rightParen) {
            increment = try parseExpression()
        }
        try consume(.rightParen, withMessage: "Expect ')' after for clauses.")
        var body = try parseStatement()
        if let increment = increment {
            body = .block(statements: [body, .expression(increment)])
        }
        var statement: Statement = .while(condition: condition, body: body)
        if let initializer = initializer {
            statement = .block(statements: [initializer, statement])
        }
        return statement
    }

    private func parseWhileStatement() throws -> Statement {
        try consume(.leftParen, withMessage: "Expect '(' after 'while'.")
        let condition = try parseExpression()
        try consume(.rightParen, withMessage: "Expect ')' after while condition.")
        let body = try parseStatement()
        return .while(condition: condition, body: body)
    }

    private func parseIfStatement() throws -> Statement {
        try consume(.leftParen, withMessage: "Expect '(' after 'if'.")
        let condition = try parseExpression()
        try consume(.rightParen, withMessage: "Expect ')' after if condition.")
        let thenBranch = try parseStatement()
        var elseBranch: Statement? = nil
        if match(.else) {
            elseBranch = try parseStatement()
        }
        return .if(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }

    private func parseBlock() throws -> [Statement] {
        var statements: [Statement] = []
        while !check(.rightBrace) && !isAtEnd {
            if let statement = parseDeclaration() {
                statements.append(statement)
            }
        }
        try consume(.rightBrace, withMessage: "Expect '}' after block.")
        return statements
    }

    private func parsePrintStatement() throws -> Statement {
        let expression = try parseExpression()
        try consume(.semicolon, withMessage: "Expect ';' after value.")
        return .print(expression: expression)
    }

    private func parseExpressionStatement() throws -> Statement {
        let expression = try parseExpression()
        try consume(.semicolon, withMessage: "Expect ';' after expression.")
        return .expression(expression)
    }

    private func parseExpression() throws -> Expression {
        try parseAssignment()
    }

    private func parseAssignment() throws -> Expression {
        let expression = try parseOr()
        if match(.equal) {
            let equals = previous()
            let value = try parseAssignment()
            if case .variable(let name) = expression {
                return .assign(name: name, value: value)
            }
            reportError(on: equals, withMessage: "Invalid assignment target.")
        }
        return expression
    }

    private func parseOr() throws -> Expression {
        var expression = try parseAnd()
        while match(.or) {
            let `operator` = previous()
            let right = try parseAnd()
            expression = .logical(left: expression, operator: `operator`, right: right)
        }
        return expression
    }

    private func parseAnd() throws -> Expression {
        var expression = try parseEquality()
        while match(.or) {
            let `operator` = previous()
            let right = try parseEquality()
            expression = .logical(left: expression, operator: `operator`, right: right)
        }
        return expression
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
        if match(.identifier) {
            return .variable(name: previous())
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

    @discardableResult private func consume(_ kind: Token.Kind, withMessage message: String) throws -> Token {
        if check(kind) {
            return advance()
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
