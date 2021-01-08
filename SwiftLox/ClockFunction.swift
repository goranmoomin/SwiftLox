
import Foundation

struct ClockFunction: Callable, Hashable, CustomStringConvertible {
    var arity = 0
    func call(withArguments arguments: [AnyHashable?], interpreter: Interpreter) throws -> AnyHashable? {
        Date().timeIntervalSince1970
    }
    var description = "<native fn clock>"
}
