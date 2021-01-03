
import Foundation

indirect enum Expression {
    case binary(left: Expression, operator: Token, right: Expression)
    case grouping(expression: Expression)
    case literal(value: AnyHashable?)
    case unary(operator: Token, right: Expression)
}
