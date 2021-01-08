
import Foundation

indirect enum Statement: Hashable {
    case block(statements: [Statement])
    case expression(Expression)
    case function(name: Token, parameters: [Token], body: [Statement])
    case `if`(condition: Expression, thenBranch: Statement, elseBranch: Statement?)
    case print(expression: Expression)
    case `return`(keyword: Token, value: Expression?)
    case `var`(name: Token, initializer: Expression?)
    case `while`(condition: Expression, body: Statement)
}
