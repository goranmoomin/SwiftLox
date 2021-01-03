
import Foundation

class Interpreter {
    struct RuntimeError: Error {
        let token: Token
        let message: String
    }

    func interpret(_ expression: Expression) {
        do {
            let evaluatedExpression = try evaluated(expression)
            print(description(of: evaluatedExpression))
        } catch {
            let error = error as! RuntimeError
            SwiftLox.report(error)
        }
    }

    private func evaluated(_ expression: Expression) throws -> AnyHashable? {
        switch expression {
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
        case .unary(let `operator`, let right):
            let right = try evaluated(right)
            switch `operator`.kind {
            case .minus: return -(right as! Double)
            case .bang: return !right.isTruthy
            default: fatalError()
            }
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
