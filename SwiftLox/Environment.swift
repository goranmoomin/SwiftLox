
import Foundation

class Environment {
    private var values: [String : AnyHashable?] = [:]
    private var enclosingEnvironment: Environment?

    init() {}

    init(enclosedBy enclosingEnvironment: Environment) {
        self.enclosingEnvironment = enclosingEnvironment
    }

    func defineVariable(named token: Token, as value: AnyHashable?) {
        values[String(token.lexeme)] = value
    }

    func getValue(of token: Token) throws -> AnyHashable? {
        if let value = values[String(token.lexeme)] {
            return value
        } else if let enclosingEnvironment = enclosingEnvironment {
            return try enclosingEnvironment.getValue(of: token)
        } else {
            throw Interpreter.RuntimeError(token: token, message: "Undefined variable '\(token.lexeme)'.")
        }
    }

    func assignValue(_ value: AnyHashable?, to token: Token) throws {
        if values[String(token.lexeme)] != nil {
            values[String(token.lexeme)] = value
        } else if let enclosingEnvironment = enclosingEnvironment {
            try enclosingEnvironment.assignValue(value, to: token)
        } else {
            throw Interpreter.RuntimeError(token: token, message: "Undefined variable '\(token.lexeme)'")
        }
    }
}
