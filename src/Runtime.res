/**
 * Runtime evaluation engine for compiled templates (ReScript)
 */

open Types

// Evaluate a variable expression (handles dot notation)
let rec evaluateVariable = (name: string, context: Js.Dict.t<Js.Json.t>): Js.Json.t => {
  let parts = Js.String.split(".", name)
  let rec traverse = (parts: array<string>, value: Js.Json.t): Js.Json.t => {
    if Js.Array.length(parts) == 0 {
      value
    } else {
      let part = parts[0]
      let rest = Js.Array.sliceFrom(1, parts)
      switch Js.Json.decodeObject(value) {
      | Some(obj) =>
        switch Js.Dict.get(obj, part) {
        | Some(nextValue) => traverse(rest, nextValue)
        | None => Js.Json.null
        }
      | None => Js.Json.null
      }
    }
  }

  let firstPart = parts[0]
  switch Js.Dict.get(context, firstPart) {
  | Some(value) => traverse(Js.Array.sliceFrom(1, parts), value)
  | None => Js.Json.null
  }
}

// Evaluate binary expressions
let evaluateBinary = (
  operator: string,
  left: Js.Json.t,
  right: Js.Json.t,
): Js.Json.t => {
  // Helper to get numeric value
  let toNum = (v: Js.Json.t): float => {
    switch Js.Json.decodeNumber(v) {
    | Some(n) => n
    | None => 0.0
    }
  }

  // Helper to get boolean value
  let toBool = (v: Js.Json.t): bool => {
    switch Js.Json.classify(v) {
    | Js.Json.JSONTrue => true
    | Js.Json.JSONFalse => false
    | Js.Json.JSONNull => false
    | Js.Json.JSONNumber(n) => n != 0.0
    | Js.Json.JSONString(s) => s != ""
    | _ => true
    }
  }

  switch operator {
  | "+" =>
    // Try string concatenation first
    switch (Js.Json.decodeString(left), Js.Json.decodeString(right)) {
    | (Some(l), Some(r)) => Js.Json.string(l ++ r)
    | _ => Js.Json.number(toNum(left) +. toNum(right))
    }
  | "-" => Js.Json.number(toNum(left) -. toNum(right))
  | "*" => Js.Json.number(toNum(left) *. toNum(right))
  | "/" => Js.Json.number(toNum(left) /. toNum(right))
  | "%" => Js.Json.number(mod_float(toNum(left), toNum(right)))
  | "==" => Js.Json.boolean(left == right)
  | "!=" => Js.Json.boolean(left != right)
  | "<" => Js.Json.boolean(toNum(left) < toNum(right))
  | "<=" => Js.Json.boolean(toNum(left) <= toNum(right))
  | ">" => Js.Json.boolean(toNum(left) > toNum(right))
  | ">=" => Js.Json.boolean(toNum(left) >= toNum(right))
  | "and" => Js.Json.boolean(toBool(left) && toBool(right))
  | "or" => Js.Json.boolean(toBool(left) || toBool(right))
  | _ => {
      Js.Console.error("Unknown operator: " ++ operator)
      Js.Json.null
    }
  }
}

// Evaluate unary expressions
let evaluateUnary = (operator: string, arg: Js.Json.t): Js.Json.t => {
  switch operator {
  | "-" =>
    switch Js.Json.decodeNumber(arg) {
    | Some(n) => Js.Json.number(-.n)
    | None => Js.Json.number(0.0)
    }
  | "!" | "not" =>
    switch Js.Json.classify(arg) {
    | Js.Json.JSONTrue => Js.Json.boolean(false)
    | Js.Json.JSONFalse => Js.Json.boolean(true)
    | Js.Json.JSONNull => Js.Json.boolean(true)
    | _ => Js.Json.boolean(false)
    }
  | _ => {
      Js.Console.error("Unknown unary operator: " ++ operator)
      Js.Json.null
    }
  }
}

// Evaluate member expressions (object.property)
let evaluateMember = (obj: Js.Json.t, property: string): Js.Json.t => {
  switch Js.Json.decodeObject(obj) {
  | Some(dict) =>
    switch Js.Dict.get(dict, property) {
    | Some(value) => value
    | None => Js.Json.null
    }
  | None => Js.Json.null
  }
}

// Main expression evaluator
let rec evaluateExpression = (
  expr: expression,
  context: Js.Dict.t<Js.Json.t>,
): Js.Json.t => {
  switch expr {
  | LiteralExpr({value}) => value
  | VariableExpr({name}) => evaluateVariable(name, context)
  | BinaryExpr({operator, left, right}) =>
    let leftVal = evaluateExpression(left, context)
    let rightVal = evaluateExpression(right, context)
    evaluateBinary(operator, leftVal, rightVal)
  | UnaryExpr({operator, argument}) =>
    let argVal = evaluateExpression(argument, context)
    evaluateUnary(operator, argVal)
  | MemberExpr({object, property}) =>
    let objVal = evaluateExpression(object, context)
    evaluateMember(objVal, property)
  | CallExpr({callee, arguments: args}) =>
    // Evaluate callee and arguments
    let fnVal = evaluateExpression(callee, context)
    let argVals = Js.Array.map(arg => evaluateExpression(arg, context), args)
    // For now, we'll just return null for function calls
    // In a full implementation, we'd support helper functions
    Js.Json.null
  }
}

// Check if a value is truthy in template context
let isTruthy = (value: Js.Json.t): bool => {
  switch Js.Json.classify(value) {
  | Js.Json.JSONNull => false
  | Js.Json.JSONFalse => false
  | Js.Json.JSONTrue => true
  | Js.Json.JSONNumber(n) => n != 0.0
  | Js.Json.JSONString(s) => s != ""
  | Js.Json.JSONArray(arr) => Js.Array.length(arr) > 0
  | Js.Json.JSONObject(obj) => Js.Array.length(Js.Dict.keys(obj)) > 0
  }
}

// Get an iterable from a value
let getIterable = (value: Js.Json.t): array<Js.Json.t> => {
  switch Js.Json.classify(value) {
  | Js.Json.JSONArray(arr) => arr
  | Js.Json.JSONObject(obj) => {
      // Convert object to array of [key, value] pairs
      let keys = Js.Dict.keys(obj)
      Js.Array.map(key => {
        let val = Js.Dict.unsafeGet(obj, key)
        Js.Json.array([Js.Json.string(key), val])
      }, keys)
    }
  | Js.Json.JSONNumber(n) =>
    // Create range from 0 to n-1
    let count = Belt.Int.fromFloat(n)
    if count > 0 {
      Belt.Array.makeBy(count, i => Js.Json.number(Belt.Int.toFloat(i)))
    } else {
      []
    }
  | _ => []
  }
}

// Get value from context by path
let getValue = (path: string, context: Js.Dict.t<Js.Json.t>): option<Js.Json.t> => {
  let value = evaluateVariable(path, context)
  if value === Js.Json.null {
    None
  } else {
    Some(value)
  }
}
