
import Foundation

class ASTPrinter {
    func printed(_ expression: Expression) -> String {
        switch expression {
        case .binary(let left, let `operator`, let right):
            return parenthesized(withName: String(`operator`.lexeme), left, right)
        case .grouping(let expression):
            return parenthesized(withName: "group", expression)
        case .literal(let value):
            guard let value = value else { return "nil" }
            return String(describing: value)
        case .unary(let `operator`, let right):
            return parenthesized(withName: String(`operator`.lexeme), right)
        }
    }

    private func parenthesized(withName name: String, _ expressions: Expression...) -> String {
        "(" + name + " " + expressions.map(printed(_:)).joined(separator: " ") + ")"
    }
}
