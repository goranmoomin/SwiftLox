
import Foundation

class Interpreter {
    private var environment = Environment()

    struct RuntimeError: Error {
        let token: Token
        let message: String
    }

    func interpret(_ statements: [Statement]) {
        do {
            for statement in statements {
                try execute(statement)
            }
        } catch {
            let error = error as! RuntimeError
            SwiftLox.report(error)
        }
    }

    private func execute(_ statement: Statement) throws {
        switch statement {
        case .block(let statements):
            try executeBlock(statements: statements, in: Environment(enclosedBy: environment))
        case .expression(let expression):
            try evaluated(expression)
        case .if(let condition, let thenBranch, let elseBranch):
            if try evaluated(condition).isTruthy {
                try execute(thenBranch)
            } else if let elseBranch = elseBranch {
                try execute(elseBranch)
            }
        case .print(let expression):
            let value = try evaluated(expression)
            print(description(of: value))
        case .var(let name, let initializer):
            var value: AnyHashable?
            if let initializer = initializer {
                value = try evaluated(initializer)
            }
            environment.defineVariable(named: name, as: value)
        case .while(let condition, let body):
            while try evaluated(condition).isTruthy {
                try execute(body)
            }
        }
    }

    private func executeBlock(statements: [Statement], in environment: Environment) throws {
        let previousEnvironment = self.environment
        self.environment = environment
        defer { self.environment = previousEnvironment }
        for statement in statements {
            try execute(statement)
        }
    }

    @discardableResult private func evaluated(_ expression: Expression) throws -> AnyHashable? {
        switch expression {
        case .assign(let name, let value):
            let value = try evaluated(value)
            try environment.assignValue(value, to: name)
            return value
        case .binary(let left, let `operator`, let right):
            let left = try evaluated(left)
            let right = try evaluated(right)
            switch `operator`.kind {
            case .greater:
                try checkNumberOperands(forOperator: `operator`, left: left, right: right)
                return (left as! Double) > (right as! Double)
            case .greaterEqual:
                try checkNumberOperands(forOperator: `operator`, left: left, right: right)
                return (left as! Double) >= (right as! Double)
            case .less:
                try checkNumberOperands(forOperator: `operator`, left: left, right: right)
                return (left as! Double) < (right as! Double)
            case .lessEqual:
                try checkNumberOperands(forOperator: `operator`, left: left, right: right)
                return (left as! Double) <= (right as! Double)
            case .bangEqual: return left != right
            case .equalEqual: return left == right
            case .minus:
                try checkNumberOperands(forOperator: `operator`, left: left, right: right)
                return (left as! Double) - (right as! Double)
            case .plus:
                if let left = left as? Double, let right = right as? Double {
                    return left + right
                } else if let left = left as? String, let right = right as? String {
                    return left + right
                } else {
                    throw RuntimeError(token: `operator`, message: "Operands must be two numbers or two strings.")
                }
            case .slash: return (left as! Double) / (right as! Double)
            case .star: return (left as! Double) * (right as! Double)
            default: fatalError()
            }
        case .grouping(let expression):
            return try evaluated(expression)
        case .literal(let value):
            return value
        case .logical(let left, let `operator`, let right):
            let left = try evaluated(left)
            switch `operator`.kind {
            case .or: if left.isTruthy { return left }
            case .and: if !left.isTruthy { return left }
            default: fatalError()
            }
            return try evaluated(right)
        case .unary(let `operator`, let right):
            let right = try evaluated(right)
            switch `operator`.kind {
            case .minus: return -(right as! Double)
            case .bang: return !right.isTruthy
            default: fatalError()
            }
        case .variable(let name):
            return try environment.getValue(of: name)
        }
    }

    private func checkNumberOperand(forOperator operator: Token, operand: AnyHashable?) throws {
        guard operand is Double else {
            throw RuntimeError(token: `operator`, message: "Operand must be a number.")
        }
    }

    private func checkNumberOperands(forOperator operator: Token, left: AnyHashable?, right: AnyHashable?) throws {
        guard left is Double, right is Double else {
            throw RuntimeError(token: `operator`, message: "Operand must be a number.")
        }
    }

    private func description(of value: AnyHashable?) -> String {
        guard let value = value else { return "nil" }
        if value is Double {
            let description = String(describing: value)
            return description.removingSuffix(".0")
        }
        return String(describing: value)
    }
}

extension Optional where Wrapped == AnyHashable {
    fileprivate var isTruthy: Bool {
        guard let self = self else { return false }
        if let self = self as? Bool { return self }
        return true
    }
}
