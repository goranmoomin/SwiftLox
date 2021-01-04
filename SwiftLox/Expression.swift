
import Foundation

indirect enum Expression {
    case assign(name: Token, value: Expression)
    case binary(left: Expression, operator: Token, right: Expression)
    case grouping(expression: Expression)
    case literal(value: AnyHashable?)
    case logical(left: Expression, operator: Token, right: Expression)
    case unary(operator: Token, right: Expression)
    case variable(name: Token)
}
