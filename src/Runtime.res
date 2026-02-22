/**
 * v3-templater — Runtime Evaluation Engine (ReScript).
 *
 * This module implements the "Virtual Machine" for executing compiled 
 * templates. It evaluates AST expressions against a dynamic data context.
 */

open Types

/**
 * VARIABLE RESOLUTION: Recursively traverses objects using dot-notation.
 * Example: `user.profile.name` -> extracts `name` from nested dictionaries.
 */
let rec evaluateVariable = (name: string, context: Js.Dict.t<Js.Json.t>): Js.Json.t => {
  // ... [Traversal implementation using split('.') and recursion]
}

/**
 * EXPRESSION KERNEL: Computes the results of binary and unary operations.
 *
 * SUPPORTED OPERATORS:
 * - Arithmetic: +, -, *, /, %
 * - Comparison: ==, !=, <, >, <=, >=
 * - Boolean: and, or, not
 *
 * TYPE COERCION: Automatically handles string concatenation vs numerical addition.
 */
let evaluateBinary = (operator: string, left: Js.Json.t, right: Js.Json.t): Js.Json.t => {
  // ... [Implementation of operator semantics]
}

/**
 * TRUTHY LOGIC: Defines the truth-value semantics for template conditions.
 * - `null` and `false` are falsy.
 * - Empty strings, arrays, and objects are falsy.
 * - Everything else is truthy.
 */
let isTruthy = (value: Js.Json.t): bool => {
  // ... [Pattern matching on JSON classification]
}
