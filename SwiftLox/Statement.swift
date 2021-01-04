
import Foundation

indirect enum Statement {
    case block(statements: [Statement])
    case expression(Expression)
    case `if`(condition: Expression, thenBranch: Statement, elseBranch: Statement?)
    case print(expression: Expression)
    case `var`(name: Token, initializer: Expression?)
    case `while`(condition: Expression, body: Statement)
}
