/// Precedence group for Combine custom operators.
///
/// Left-associative, between function arrows and ternary operator.
/// Used by operators like `&`, `+`, `??` for publishers.
precedencegroup CombinePrecedence {
    associativity: left
    higherThan: FunctionArrowPrecedence
    lowerThan: TernaryPrecedence
}
