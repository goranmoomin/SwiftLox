
import Foundation

class Environment {
    private var values: [String : AnyHashable?] = [:]
    private var enclosingEnvironment: Environment?

    init() {}

    init(enclosedBy enclosingEnvironment: Environment) {
        self.enclosingEnvironment = enclosingEnvironment
    }

    func defineVariable(named name: String, as value: AnyHashable?) {
        values[name] = value
    }

    func defineVariable(named token: Token, as value: AnyHashable?) {
        defineVariable(named: String(token.lexeme), as: value)
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

extension Environment: Hashable {
    static func == (lhs: Environment, rhs: Environment) -> Bool {
        lhs.values == rhs.values && lhs.enclosingEnvironment == rhs.enclosingEnvironment
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(values)
        hasher.combine(enclosingEnvironment)
    }
}
