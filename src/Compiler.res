/**
 * Compiler for v3-templater (ReScript)
 * Renders AST nodes to output string
 */

open Types

// Compiler options
type compilerOptions = {
  autoEscape: bool,
  strictMode: bool,
  filters: Js.Dict.t<filterFunction>,
  helpers: Js.Dict.t<helperFunction>,
}

// Default options
let defaultOptions: compilerOptions = {
  autoEscape: true,
  strictMode: false,
  filters: Js.Dict.empty(),
  helpers: Js.Dict.empty(),
}

// JSON value to string
let jsonToString = (value: Js.Json.t): string => {
  switch Js.Json.classify(value) {
  | Js.Json.JSONString(s) => s
  | Js.Json.JSONNumber(n) => Js.Float.toString(n)
  | Js.Json.JSONTrue => "true"
  | Js.Json.JSONFalse => "false"
  | Js.Json.JSONNull => ""
  | Js.Json.JSONArray(arr) =>
    "[" ++
    Js.Array.joinWith(", ", Js.Array.map(item => Js.Json.stringify(item), arr)) ++
    "]"
  | Js.Json.JSONObject(_) => Js.Json.stringify(value)
  }
}

// Apply HTML escaping
let escapeHtml = (str: string): string => {
  str
  ->Js.String.replaceByRe(%re("/&/g"), "&amp;")
  ->Js.String.replaceByRe(%re("/</g"), "&lt;")
  ->Js.String.replaceByRe(%re("/>/g"), "&gt;")
  ->Js.String.replaceByRe(%re("/\"/g"), "&quot;")
  ->Js.String.replaceByRe(%re("/'/g"), "&#x27;")
}

// Check if value is a SafeString (marked safe, no escaping)
let isSafeString = (value: Js.Json.t): bool => {
  switch Js.Json.decodeObject(value) {
  | Some(obj) =>
    switch Js.Dict.get(obj, "__safe") {
    | Some(_) => true
    | None => false
    }
  | None => false
  }
}

// Get string value from SafeString or regular string
let getSafeStringValue = (value: Js.Json.t): string => {
  switch Js.Json.decodeObject(value) {
  | Some(obj) =>
    switch Js.Dict.get(obj, "value") {
    | Some(v) =>
      switch Js.Json.decodeString(v) {
      | Some(s) => s
      | None => jsonToString(value)
      }
    | None => jsonToString(value)
    }
  | None => jsonToString(value)
  }
}

// Apply a single filter
let applyFilter = (
  value: Js.Json.t,
  filter: filterCall,
  filters: Js.Dict.t<filterFunction>,
): Js.Json.t => {
  switch Js.Dict.get(filters, filter.name) {
  | Some(filterFn) => filterFn(. value, filter.args)
  | None =>
    // Built-in filters fallback
    switch filter.name {
    | "safe" =>
      // Mark as safe (no escaping)
      let obj = Js.Dict.empty()
      Js.Dict.set(obj, "__safe", Js.Json.boolean(true))
      Js.Dict.set(obj, "value", Js.Json.string(jsonToString(value)))
      Js.Json.object_(obj)
    | "escape" | "e" => Js.Json.string(escapeHtml(jsonToString(value)))
    | "upper" => Js.Json.string(Js.String.toUpperCase(jsonToString(value)))
    | "lower" => Js.Json.string(Js.String.toLowerCase(jsonToString(value)))
    | "capitalize" =>
      let s = jsonToString(value)
      if Js.String.length(s) > 0 {
        Js.Json.string(
          Js.String.toUpperCase(Js.String.charAt(0, s)) ++
            Js.String.toLowerCase(Js.String.substringToEnd(~from=1, s)),
        )
      } else {
        value
      }
    | "trim" => Js.Json.string(Js.String.trim(jsonToString(value)))
    | "length" =>
      switch Js.Json.classify(value) {
      | Js.Json.JSONArray(arr) => Js.Json.number(Js.Int.toFloat(Js.Array.length(arr)))
      | Js.Json.JSONString(s) => Js.Json.number(Js.Int.toFloat(Js.String.length(s)))
      | _ => Js.Json.number(0.0)
      }
    | "first" =>
      switch Js.Json.decodeArray(value) {
      | Some(arr) if Js.Array.length(arr) > 0 => arr[0]
      | _ => Js.Json.null
      }
    | "last" =>
      switch Js.Json.decodeArray(value) {
      | Some(arr) if Js.Array.length(arr) > 0 => arr[Js.Array.length(arr) - 1]
      | _ => Js.Json.null
      }
    | "reverse" =>
      switch Js.Json.decodeArray(value) {
      | Some(arr) =>
        let copy = Js.Array.copy(arr)
        let _ = Js.Array.reverseInPlace(copy)
        Js.Json.array(copy)
      | None =>
        let s = jsonToString(value)
        Js.Json.string(
          Js.Array.joinWith("", Js.Array.reverseInPlace(Js.String.split("", s))),
        )
      }
    | "join" =>
      let separator = switch filter.args[0] {
      | exception _ => ", "
      | arg =>
        switch Js.Json.decodeString(arg) {
        | Some(s) => s
        | None => ", "
        }
      }
      switch Js.Json.decodeArray(value) {
      | Some(arr) => Js.Json.string(Js.Array.joinWith(separator, Js.Array.map(jsonToString, arr)))
      | None => value
      }
    | "default" =>
      let isEmpty = switch Js.Json.classify(value) {
      | Js.Json.JSONNull => true
      | Js.Json.JSONString(s) => s == ""
      | Js.Json.JSONArray(arr) => Js.Array.length(arr) == 0
      | _ => false
      }
      if isEmpty {
        switch filter.args[0] {
        | exception _ => value
        | defaultVal => defaultVal
        }
      } else {
        value
      }
    | "abs" =>
      switch Js.Json.decodeNumber(value) {
      | Some(n) => Js.Json.number(Js.Math.abs_float(n))
      | None => value
      }
    | "round" =>
      switch Js.Json.decodeNumber(value) {
      | Some(n) => Js.Json.number(Js.Math.round(n))
      | None => value
      }
    | "floor" =>
      switch Js.Json.decodeNumber(value) {
      | Some(n) => Js.Json.number(Js.Math.floor_float(n))
      | None => value
      }
    | "ceil" =>
      switch Js.Json.decodeNumber(value) {
      | Some(n) => Js.Json.number(Js.Math.ceil_float(n))
      | None => value
      }
    | "truncate" =>
      let length = switch filter.args[0] {
      | exception _ => 50
      | arg =>
        switch Js.Json.decodeNumber(arg) {
        | Some(n) => Belt.Int.fromFloat(n)
        | None => 50
        }
      }
      let s = jsonToString(value)
      if Js.String.length(s) > length {
        Js.Json.string(Js.String.substring(~from=0, ~to_=length, s) ++ "...")
      } else {
        Js.Json.string(s)
      }
    | "replace" =>
      let search = switch filter.args[0] {
      | exception _ => ""
      | arg =>
        switch Js.Json.decodeString(arg) {
        | Some(s) => s
        | None => ""
        }
      }
      let replacement = switch filter.args[1] {
      | exception _ => ""
      | arg =>
        switch Js.Json.decodeString(arg) {
        | Some(s) => s
        | None => ""
        }
      }
      let s = jsonToString(value)
      Js.Json.string(Js.String.replace(search, replacement, s))
    | "split" =>
      let separator = switch filter.args[0] {
      | exception _ => " "
      | arg =>
        switch Js.Json.decodeString(arg) {
        | Some(s) => s
        | None => " "
        }
      }
      let s = jsonToString(value)
      Js.Json.array(Js.Array.map(Js.Json.string, Js.String.split(separator, s)))
    | "keys" =>
      switch Js.Json.decodeObject(value) {
      | Some(obj) => Js.Json.array(Js.Array.map(Js.Json.string, Js.Dict.keys(obj)))
      | None => Js.Json.array([])
      }
    | "values" =>
      switch Js.Json.decodeObject(value) {
      | Some(obj) => Js.Json.array(Js.Dict.values(obj))
      | None => Js.Json.array([])
      }
    | "json" => Js.Json.string(Js.Json.stringify(value))
    | "striptags" =>
      let s = jsonToString(value)
      Js.Json.string(Js.String.replaceByRe(%re("/<[^>]*>/g"), "", s))
    | "nl2br" =>
      let s = jsonToString(value)
      let result = Js.String.replaceByRe(%re("/\\n/g"), "<br>", s)
      // Mark as safe since we're adding HTML
      let obj = Js.Dict.empty()
      Js.Dict.set(obj, "__safe", Js.Json.boolean(true))
      Js.Dict.set(obj, "value", Js.Json.string(result))
      Js.Json.object_(obj)
    | "fixed" =>
      let decimals = switch filter.args[0] {
      | exception _ => 2
      | arg =>
        switch Js.Json.decodeNumber(arg) {
        | Some(n) => Belt.Int.fromFloat(n)
        | None => 2
        }
      }
      switch Js.Json.decodeNumber(value) {
      | Some(n) => Js.Json.string(Js.Float.toFixedWithPrecision(n, ~digits=decimals))
      | None => value
      }
    | "slice" =>
      let start = switch filter.args[0] {
      | exception _ => 0
      | arg =>
        switch Js.Json.decodeNumber(arg) {
        | Some(n) => Belt.Int.fromFloat(n)
        | None => 0
        }
      }
      let end_ = switch filter.args[1] {
      | exception _ => None
      | arg =>
        switch Js.Json.decodeNumber(arg) {
        | Some(n) => Some(Belt.Int.fromFloat(n))
        | None => None
        }
      }
      switch Js.Json.classify(value) {
      | Js.Json.JSONArray(arr) =>
        switch end_ {
        | Some(e) => Js.Json.array(Js.Array.slice(~start, ~end_=e, arr))
        | None => Js.Json.array(Js.Array.sliceFrom(start, arr))
        }
      | Js.Json.JSONString(s) =>
        switch end_ {
        | Some(e) => Js.Json.string(Js.String.slice(~from=start, ~to_=e, s))
        | None => Js.Json.string(Js.String.sliceToEnd(~from=start, s))
        }
      | _ => value
      }
    | "sort" =>
      switch Js.Json.decodeArray(value) {
      | Some(arr) =>
        let copy = Js.Array.copy(arr)
        let _ = Js.Array.sortInPlace(copy)
        Js.Json.array(copy)
      | None => value
      }
    | "unique" =>
      switch Js.Json.decodeArray(value) {
      | Some(arr) =>
        let seen = Js.Dict.empty()
        let unique = Js.Array.filter(item => {
          let key = Js.Json.stringify(item)
          switch Js.Dict.get(seen, key) {
          | Some(_) => false
          | None =>
            Js.Dict.set(seen, key, true)
            true
          }
        }, arr)
        Js.Json.array(unique)
      | None => value
      }
    | "title" =>
      let s = jsonToString(value)
      let words = Js.String.split(" ", s)
      let titled = Js.Array.map(word => {
        if Js.String.length(word) > 0 {
          Js.String.toUpperCase(Js.String.charAt(0, word)) ++
            Js.String.toLowerCase(Js.String.substringToEnd(~from=1, word))
        } else {
          word
        }
      }, words)
      Js.Json.string(Js.Array.joinWith(" ", titled))
    | "wordcount" =>
      let s = jsonToString(value)
      let words = Js.Array.filter(
        w => Js.String.trim(w) != "",
        Js.String.splitByRe(%re("/\\s+/"), s),
      )
      Js.Json.number(Js.Int.toFloat(Js.Array.length(words)))
    | _ =>
      // Unknown filter, return value unchanged
      Js.Console.warn("Unknown filter: " ++ filter.name)
      value
    }
  }
}

// Apply all filters to a value
let applyFilters = (
  value: Js.Json.t,
  filters_: array<filterCall>,
  filterDict: Js.Dict.t<filterFunction>,
): Js.Json.t => {
  Js.Array.reduce((acc, filter) => applyFilter(acc, filter, filterDict), value, filters_)
}

// Create loop context with special variables
let createLoopContext = (
  index: int,
  length: int,
  parentContext: Js.Dict.t<Js.Json.t>,
): Js.Dict.t<Js.Json.t> => {
  let loop = Js.Dict.empty()
  Js.Dict.set(loop, "index", Js.Json.number(Js.Int.toFloat(index + 1))) // 1-based
  Js.Dict.set(loop, "index0", Js.Json.number(Js.Int.toFloat(index))) // 0-based
  Js.Dict.set(loop, "first", Js.Json.boolean(index == 0))
  Js.Dict.set(loop, "last", Js.Json.boolean(index == length - 1))
  Js.Dict.set(loop, "length", Js.Json.number(Js.Int.toFloat(length)))
  Js.Dict.set(loop, "revindex", Js.Json.number(Js.Int.toFloat(length - index))) // 1-based from end
  Js.Dict.set(loop, "revindex0", Js.Json.number(Js.Int.toFloat(length - index - 1))) // 0-based from end

  // Clone parent context and add loop
  let newContext = Js.Dict.fromArray(Js.Dict.entries(parentContext))
  Js.Dict.set(newContext, "loop", Js.Json.object_(loop))
  newContext
}

// Main compiler - render AST to string
let rec render = (
  nodes: array<astNode>,
  context: Js.Dict.t<Js.Json.t>,
  options: compilerOptions,
): string => {
  Js.Array.reduce((acc, node) => acc ++ renderNode(node, context, options), "", nodes)
}

// Render a single node
and renderNode = (
  node: astNode,
  context: Js.Dict.t<Js.Json.t>,
  options: compilerOptions,
): string => {
  switch node {
  | TextNode({value}) => value

  | VariableNode({name, filters}) =>
    let value = Runtime.evaluateVariable(name, context)
    let filtered = applyFilters(value, filters, options.filters)

    // Handle escaping
    if isSafeString(filtered) {
      getSafeStringValue(filtered)
    } else if options.autoEscape {
      escapeHtml(jsonToString(filtered))
    } else {
      jsonToString(filtered)
    }

  | IfNode({condition, consequent, alternate, elseIfs}) =>
    let condValue = Runtime.evaluateExpression(condition, context)
    if Runtime.isTruthy(condValue) {
      render(consequent, context, options)
    } else {
      // Check elif branches
      let elifResult = switch elseIfs {
      | Some(branches) =>
        let found = ref(None)
        Js.Array.forEach(branch => {
          if found.contents == None {
            let branchCond = Runtime.evaluateExpression(branch.condition, context)
            if Runtime.isTruthy(branchCond) {
              found := Some(render(branch.body, context, options))
            }
          }
        }, branches)
        found.contents
      | None => None
      }

      switch elifResult {
      | Some(result) => result
      | None =>
        switch alternate {
        | Some(alt) => render(alt, context, options)
        | None => ""
        }
      }
    }

  | ForNode({variable, iterable, body, indexVar}) =>
    let iterValue = Runtime.evaluateExpression(iterable, context)
    let items = Runtime.getIterable(iterValue)
    let length = Js.Array.length(items)

    Js.Array.reducei((acc, item, index) => {
      let loopContext = createLoopContext(index, length, context)
      Js.Dict.set(loopContext, variable, item)

      // Set index variable if specified
      switch indexVar {
      | Some(idx) => Js.Dict.set(loopContext, idx, Js.Json.number(Js.Int.toFloat(index)))
      | None => ()
      }

      acc ++ render(body, loopContext, options)
    }, "", items)

  | BlockNode({name: _, body}) =>
    // For now, just render the block content
    // Full inheritance support would need template loading
    render(body, context, options)

  | IncludeNode(_) =>
    // Include requires file loading - return placeholder
    "<!-- include not implemented in sync mode -->"

  | ExtendsNode(_) =>
    // Extends requires file loading - return empty
    ""

  | FilterNode({name, args: _}) =>
    // Standalone filter application - rare
    Js.Console.warn("Standalone filter node: " ++ name)
    ""
  }
}

// Compile template string to render function
let compile = (
  template: string,
  options: option<compilerOptions>,
  delimiters: option<delimiters>,
): compiledTemplate => {
  let opts = switch options {
  | Some(o) => o
  | None => defaultOptions
  }

  let ast = Parser.parseTemplate(template, delimiters)

  {
    render: (. context) => render(ast, context, opts),
    source: template,
    ast: switch ast[0] {
    | exception _ => TextNode({value: ""})
    | node => node
    },
  }
}

// Direct render (compile + execute)
let renderTemplate = (
  template: string,
  context: Js.Dict.t<Js.Json.t>,
  options: option<compilerOptions>,
  delimiters: option<delimiters>,
): string => {
  let compiled = compile(template, options, delimiters)
  compiled.render(. context)
}
