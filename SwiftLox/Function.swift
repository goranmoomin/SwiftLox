
import Foundation

struct Function: Callable, Hashable, CustomStringConvertible {
    let name: Token
    let parameters: [Token]
    let body: [Statement]
    let enclosingEnvironment: Environment

    var arity: Int  {
        parameters.count
    }

    func call(withArguments arguments: [AnyHashable?], interpreter: Interpreter) throws -> AnyHashable? {
        let environment = Environment(enclosedBy: enclosingEnvironment)
        for (parameter, argument) in zip(parameters, arguments) {
            environment.defineVariable(named: parameter, as: argument)
        }
        do {
            try interpreter.executeBlock(statements: body, in: environment)
        } catch let error as Interpreter.Return {
            return error.value
        }
        return nil
    }

    var description: String {
        "<fn \(name.lexeme)>"
    }
}
