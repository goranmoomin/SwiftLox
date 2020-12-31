
import Foundation

extension Character {
    var isDigit: Bool {
        self >= "0" && self <= "9"
    }

    var isAlpha: Bool {
        self >= "a" && self <= "z" || self >= "A" && self <= "Z" || self == "_"
    }

    var isAlphaNumeric: Bool {
        isAlpha || isDigit
    }
}
