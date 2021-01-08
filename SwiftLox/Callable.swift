
import Foundation

protocol Callable {
    var arity: Int { get }
    func call(withArguments arguments: [AnyHashable?], interpreter: Interpreter) throws -> AnyHashable?
}
