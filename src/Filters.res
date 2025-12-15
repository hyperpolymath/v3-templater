/**
 * Built-in filters for v3-templater (ReScript)
 * Provides 30+ filters for string, array, number, and utility transformations
 */

open Types

// Helper to convert JSON to string
let toString = (value: Js.Json.t): string => {
  switch Js.Json.classify(value) {
  | Js.Json.JSONString(s) => s
  | Js.Json.JSONNumber(n) => Js.Float.toString(n)
  | Js.Json.JSONTrue => "true"
  | Js.Json.JSONFalse => "false"
  | Js.Json.JSONNull => ""
  | _ => Js.Json.stringify(value)
  }
}

// Helper to get number
let toNumber = (value: Js.Json.t): float => {
  switch Js.Json.decodeNumber(value) {
  | Some(n) => n
  | None =>
    switch Js.Json.decodeString(value) {
    | Some(s) =>
      let n = Js.Float.fromString(s)
      if Js.Float.isNaN(n) {
        0.0
      } else {
        n
      }
    | None => 0.0
    }
  }
}

// Helper to get arg with default
let getArg = (args: array<Js.Json.t>, index: int, default: Js.Json.t): Js.Json.t => {
  switch args[index] {
  | exception _ => default
  | arg => arg
  }
}

let getStringArg = (args: array<Js.Json.t>, index: int, default: string): string => {
  switch Js.Json.decodeString(getArg(args, index, Js.Json.string(default))) {
  | Some(s) => s
  | None => default
  }
}

let getNumberArg = (args: array<Js.Json.t>, index: int, default: float): float => {
  toNumber(getArg(args, index, Js.Json.number(default)))
}

// ============= STRING FILTERS =============

let upper: filterFunction = (. value, _args) => {
  Js.Json.string(Js.String.toUpperCase(toString(value)))
}

let lower: filterFunction = (. value, _args) => {
  Js.Json.string(Js.String.toLowerCase(toString(value)))
}

let capitalize: filterFunction = (. value, _args) => {
  let s = toString(value)
  if Js.String.length(s) > 0 {
    Js.Json.string(
      Js.String.toUpperCase(Js.String.charAt(0, s)) ++
        Js.String.toLowerCase(Js.String.substringToEnd(~from=1, s)),
    )
  } else {
    value
  }
}

let title: filterFunction = (. value, _args) => {
  let s = toString(value)
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
}

let trim: filterFunction = (. value, _args) => {
  Js.Json.string(Js.String.trim(toString(value)))
}

let ltrim: filterFunction = (. value, _args) => {
  Js.Json.string(Js.String.replaceByRe(%re("/^\\s+/"), "", toString(value)))
}

let rtrim: filterFunction = (. value, _args) => {
  Js.Json.string(Js.String.replaceByRe(%re("/\\s+$/"), "", toString(value)))
}

let truncate: filterFunction = (. value, args) => {
  let length = Belt.Int.fromFloat(getNumberArg(args, 0, 50.0))
  let suffix = getStringArg(args, 1, "...")
  let s = toString(value)
  if Js.String.length(s) > length {
    Js.Json.string(Js.String.substring(~from=0, ~to_=length, s) ++ suffix)
  } else {
    Js.Json.string(s)
  }
}

let wordwrap: filterFunction = (. value, args) => {
  let width = Belt.Int.fromFloat(getNumberArg(args, 0, 80.0))
  let s = toString(value)
  let words = Js.String.split(" ", s)

  let result = ref("")
  let line = ref("")

  Js.Array.forEach(word => {
    if Js.String.length(line.contents) + Js.String.length(word) + 1 > width {
      result := result.contents ++ line.contents ++ "\n"
      line := word
    } else if line.contents == "" {
      line := word
    } else {
      line := line.contents ++ " " ++ word
    }
  }, words)

  result := result.contents ++ line.contents
  Js.Json.string(result.contents)
}

let center: filterFunction = (. value, args) => {
  let width = Belt.Int.fromFloat(getNumberArg(args, 0, 80.0))
  let s = toString(value)
  let len = Js.String.length(s)
  if len >= width {
    Js.Json.string(s)
  } else {
    let padding = width - len
    let leftPad = padding / 2
    let rightPad = padding - leftPad
    Js.Json.string(
      Js.String.repeat(leftPad, " ") ++ s ++ Js.String.repeat(rightPad, " "),
    )
  }
}

let pad: filterFunction = (. value, args) => {
  let width = Belt.Int.fromFloat(getNumberArg(args, 0, 0.0))
  let char = getStringArg(args, 1, " ")
  let side = getStringArg(args, 2, "left")
  let s = toString(value)
  let len = Js.String.length(s)

  if len >= width {
    Js.Json.string(s)
  } else {
    let padding = Js.String.repeat(width - len, char)
    switch side {
    | "right" => Js.Json.string(s ++ padding)
    | "both" =>
      let half = (width - len) / 2
      let leftPad = Js.String.repeat(half, char)
      let rightPad = Js.String.repeat(width - len - half, char)
      Js.Json.string(leftPad ++ s ++ rightPad)
    | _ => Js.Json.string(padding ++ s) // left is default
    }
  }
}

let replace: filterFunction = (. value, args) => {
  let search = getStringArg(args, 0, "")
  let replacement = getStringArg(args, 1, "")
  Js.Json.string(Js.String.replace(search, replacement, toString(value)))
}

let replaceAll: filterFunction = (. value, args) => {
  let search = getStringArg(args, 0, "")
  let replacement = getStringArg(args, 1, "")
  let s = toString(value)
  // Use split and join for replaceAll
  Js.Json.string(Js.Array.joinWith(replacement, Js.String.split(search, s)))
}

let split: filterFunction = (. value, args) => {
  let separator = getStringArg(args, 0, " ")
  Js.Json.array(Js.Array.map(Js.Json.string, Js.String.split(separator, toString(value))))
}

let striptags: filterFunction = (. value, _args) => {
  Js.Json.string(Js.String.replaceByRe(%re("/<[^>]*>/g"), "", toString(value)))
}

let nl2br: filterFunction = (. value, _args) => {
  let result = Js.String.replaceByRe(%re("/\\n/g"), "<br>", toString(value))
  // Return as SafeString
  let obj = Js.Dict.empty()
  Js.Dict.set(obj, "__safe", Js.Json.boolean(true))
  Js.Dict.set(obj, "value", Js.Json.string(result))
  Js.Json.object_(obj)
}

let urlEncode: filterFunction = (. value, _args) => {
  Js.Json.string(Js.Global.encodeURIComponent(toString(value)))
}

let urlDecode: filterFunction = (. value, _args) => {
  Js.Json.string(Js.Global.decodeURIComponent(toString(value)))
}

// ============= ARRAY FILTERS =============

let length: filterFunction = (. value, _args) => {
  switch Js.Json.classify(value) {
  | Js.Json.JSONArray(arr) => Js.Json.number(Js.Int.toFloat(Js.Array.length(arr)))
  | Js.Json.JSONString(s) => Js.Json.number(Js.Int.toFloat(Js.String.length(s)))
  | Js.Json.JSONObject(obj) => Js.Json.number(Js.Int.toFloat(Js.Array.length(Js.Dict.keys(obj))))
  | _ => Js.Json.number(0.0)
  }
}

let first: filterFunction = (. value, _args) => {
  switch Js.Json.decodeArray(value) {
  | Some(arr) if Js.Array.length(arr) > 0 => arr[0]
  | _ =>
    let s = toString(value)
    if Js.String.length(s) > 0 {
      Js.Json.string(Js.String.charAt(0, s))
    } else {
      Js.Json.null
    }
  }
}

let last: filterFunction = (. value, _args) => {
  switch Js.Json.decodeArray(value) {
  | Some(arr) if Js.Array.length(arr) > 0 => arr[Js.Array.length(arr) - 1]
  | _ =>
    let s = toString(value)
    let len = Js.String.length(s)
    if len > 0 {
      Js.Json.string(Js.String.charAt(len - 1, s))
    } else {
      Js.Json.null
    }
  }
}

let reverse: filterFunction = (. value, _args) => {
  switch Js.Json.decodeArray(value) {
  | Some(arr) =>
    let copy = Js.Array.copy(arr)
    let _ = Js.Array.reverseInPlace(copy)
    Js.Json.array(copy)
  | None =>
    let s = toString(value)
    Js.Json.string(Js.Array.joinWith("", Js.Array.reverseInPlace(Js.String.split("", s))))
  }
}

let join: filterFunction = (. value, args) => {
  let separator = getStringArg(args, 0, ", ")
  switch Js.Json.decodeArray(value) {
  | Some(arr) => Js.Json.string(Js.Array.joinWith(separator, Js.Array.map(toString, arr)))
  | None => value
  }
}

let sort: filterFunction = (. value, _args) => {
  switch Js.Json.decodeArray(value) {
  | Some(arr) =>
    let copy = Js.Array.copy(arr)
    let _ = Js.Array.sortInPlaceWith((a, b) => {
      let aStr = toString(a)
      let bStr = toString(b)
      Js.String.localeCompare(bStr, aStr)->Belt.Int.fromFloat
    }, copy)
    Js.Json.array(copy)
  | None => value
  }
}

let sortBy: filterFunction = (. value, args) => {
  let key = getStringArg(args, 0, "")
  switch Js.Json.decodeArray(value) {
  | Some(arr) =>
    let copy = Js.Array.copy(arr)
    let _ = Js.Array.sortInPlaceWith((a, b) => {
      let aVal = switch Js.Json.decodeObject(a) {
      | Some(obj) =>
        switch Js.Dict.get(obj, key) {
        | Some(v) => toString(v)
        | None => ""
        }
      | None => ""
      }
      let bVal = switch Js.Json.decodeObject(b) {
      | Some(obj) =>
        switch Js.Dict.get(obj, key) {
        | Some(v) => toString(v)
        | None => ""
        }
      | None => ""
      }
      Js.String.localeCompare(bVal, aVal)->Belt.Int.fromFloat
    }, copy)
    Js.Json.array(copy)
  | None => value
  }
}

let unique: filterFunction = (. value, _args) => {
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
}

let slice: filterFunction = (. value, args) => {
  let start = Belt.Int.fromFloat(getNumberArg(args, 0, 0.0))
  let end_ = switch args[1] {
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
}

let batch: filterFunction = (. value, args) => {
  let size = Belt.Int.fromFloat(getNumberArg(args, 0, 1.0))
  switch Js.Json.decodeArray(value) {
  | Some(arr) =>
    let batches = []
    let len = Js.Array.length(arr)
    let i = ref(0)
    while i.contents < len {
      let batch = Js.Array.slice(~start=i.contents, ~end_=i.contents + size, arr)
      let _ = Js.Array.push(Js.Json.array(batch), batches)
      i := i.contents + size
    }
    Js.Json.array(batches)
  | None => value
  }
}

let map: filterFunction = (. value, args) => {
  let key = getStringArg(args, 0, "")
  switch Js.Json.decodeArray(value) {
  | Some(arr) =>
    Js.Json.array(
      Js.Array.map(item => {
        switch Js.Json.decodeObject(item) {
        | Some(obj) =>
          switch Js.Dict.get(obj, key) {
          | Some(v) => v
          | None => Js.Json.null
          }
        | None => item
        }
      }, arr),
    )
  | None => value
  }
}

let reject: filterFunction = (. value, args) => {
  let key = getStringArg(args, 0, "")
  let testValue = getArg(args, 1, Js.Json.boolean(true))
  switch Js.Json.decodeArray(value) {
  | Some(arr) =>
    Js.Json.array(
      Js.Array.filter(item => {
        switch Js.Json.decodeObject(item) {
        | Some(obj) =>
          switch Js.Dict.get(obj, key) {
          | Some(v) => v != testValue
          | None => true
          }
        | None => true
        }
      }, arr),
    )
  | None => value
  }
}

let select: filterFunction = (. value, args) => {
  let key = getStringArg(args, 0, "")
  let testValue = getArg(args, 1, Js.Json.boolean(true))
  switch Js.Json.decodeArray(value) {
  | Some(arr) =>
    Js.Json.array(
      Js.Array.filter(item => {
        switch Js.Json.decodeObject(item) {
        | Some(obj) =>
          switch Js.Dict.get(obj, key) {
          | Some(v) => v == testValue
          | None => false
          }
        | None => false
        }
      }, arr),
    )
  | None => value
  }
}

let groupBy: filterFunction = (. value, args) => {
  let key = getStringArg(args, 0, "")
  switch Js.Json.decodeArray(value) {
  | Some(arr) =>
    let groups = Js.Dict.empty()
    Js.Array.forEach(item => {
      let groupKey = switch Js.Json.decodeObject(item) {
      | Some(obj) =>
        switch Js.Dict.get(obj, key) {
        | Some(v) => toString(v)
        | None => ""
        }
      | None => ""
      }
      let group = switch Js.Dict.get(groups, groupKey) {
      | Some(g) =>
        switch Js.Json.decodeArray(g) {
        | Some(arr) => arr
        | None => []
        }
      | None => []
      }
      let _ = Js.Array.push(item, group)
      Js.Dict.set(groups, groupKey, Js.Json.array(group))
    }, arr)
    Js.Json.object_(groups)
  | None => value
  }
}

// ============= NUMBER FILTERS =============

let abs: filterFunction = (. value, _args) => {
  Js.Json.number(Js.Math.abs_float(toNumber(value)))
}

let round: filterFunction = (. value, args) => {
  let precision = Belt.Int.fromFloat(getNumberArg(args, 0, 0.0))
  let n = toNumber(value)
  if precision == 0 {
    Js.Json.number(Js.Math.round(n))
  } else {
    let factor = Js.Math.pow_float(~base=10.0, ~exp=Js.Int.toFloat(precision))
    Js.Json.number(Js.Math.round(n *. factor) /. factor)
  }
}

let floor: filterFunction = (. value, _args) => {
  Js.Json.number(Js.Math.floor_float(toNumber(value)))
}

let ceil: filterFunction = (. value, _args) => {
  Js.Json.number(Js.Math.ceil_float(toNumber(value)))
}

let fixed: filterFunction = (. value, args) => {
  let decimals = Belt.Int.fromFloat(getNumberArg(args, 0, 2.0))
  Js.Json.string(Js.Float.toFixedWithPrecision(toNumber(value), ~digits=decimals))
}

let formatNumber: filterFunction = (. value, args) => {
  let decimals = Belt.Int.fromFloat(getNumberArg(args, 0, 0.0))
  let decSep = getStringArg(args, 1, ".")
  let thousandsSep = getStringArg(args, 2, ",")

  let n = toNumber(value)
  let fixed = Js.Float.toFixedWithPrecision(Js.Math.abs_float(n), ~digits=decimals)
  let parts = Js.String.split(".", fixed)
  let intPart = parts[0]
  let decPart = switch parts[1] {
  | exception _ => ""
  | d => d
  }

  // Add thousands separators
  let len = Js.String.length(intPart)
  let formatted = ref("")
  for i in 0 to len - 1 {
    if i > 0 && mod(len - i, 3) == 0 {
      formatted := formatted.contents ++ thousandsSep
    }
    formatted := formatted.contents ++ Js.String.charAt(i, intPart)
  }

  let result = if decimals > 0 {
    formatted.contents ++ decSep ++ decPart
  } else {
    formatted.contents
  }

  Js.Json.string(if n < 0.0 { "-" ++ result } else { result })
}

// ============= UTILITY FILTERS =============

let default: filterFunction = (. value, args) => {
  let isEmpty = switch Js.Json.classify(value) {
  | Js.Json.JSONNull => true
  | Js.Json.JSONString(s) => s == ""
  | Js.Json.JSONArray(arr) => Js.Array.length(arr) == 0
  | Js.Json.JSONFalse => true
  | _ => false
  }
  if isEmpty {
    getArg(args, 0, value)
  } else {
    value
  }
}

let safe: filterFunction = (. value, _args) => {
  let obj = Js.Dict.empty()
  Js.Dict.set(obj, "__safe", Js.Json.boolean(true))
  Js.Dict.set(obj, "value", Js.Json.string(toString(value)))
  Js.Json.object_(obj)
}

let escape: filterFunction = (. value, _args) => {
  let s = toString(value)
  Js.Json.string(
    s
    ->Js.String.replaceByRe(%re("/&/g"), "&amp;")
    ->Js.String.replaceByRe(%re("/</g"), "&lt;")
    ->Js.String.replaceByRe(%re("/>/g"), "&gt;")
    ->Js.String.replaceByRe(%re("/\"/g"), "&quot;")
    ->Js.String.replaceByRe(%re("/'/g"), "&#x27;"),
  )
}

let json: filterFunction = (. value, args) => {
  let indent = Belt.Int.fromFloat(getNumberArg(args, 0, 0.0))
  if indent > 0 {
    Js.Json.string(Js.Json.stringifyWithSpace(value, indent))
  } else {
    Js.Json.string(Js.Json.stringify(value))
  }
}

let keys: filterFunction = (. value, _args) => {
  switch Js.Json.decodeObject(value) {
  | Some(obj) => Js.Json.array(Js.Array.map(Js.Json.string, Js.Dict.keys(obj)))
  | None => Js.Json.array([])
  }
}

let values: filterFunction = (. value, _args) => {
  switch Js.Json.decodeObject(value) {
  | Some(obj) => Js.Json.array(Js.Dict.values(obj))
  | None => Js.Json.array([])
  }
}

let entries: filterFunction = (. value, _args) => {
  switch Js.Json.decodeObject(value) {
  | Some(obj) =>
    Js.Json.array(
      Js.Array.map(((k, v)) => Js.Json.array([Js.Json.string(k), v]), Js.Dict.entries(obj)),
    )
  | None => Js.Json.array([])
  }
}

let typeOf: filterFunction = (. value, _args) => {
  switch Js.Json.classify(value) {
  | Js.Json.JSONNull => Js.Json.string("null")
  | Js.Json.JSONTrue | Js.Json.JSONFalse => Js.Json.string("boolean")
  | Js.Json.JSONNumber(_) => Js.Json.string("number")
  | Js.Json.JSONString(_) => Js.Json.string("string")
  | Js.Json.JSONArray(_) => Js.Json.string("array")
  | Js.Json.JSONObject(_) => Js.Json.string("object")
  }
}

let wordcount: filterFunction = (. value, _args) => {
  let s = toString(value)
  let words = Js.Array.filter(w => {
    switch w {
    | Some(word) => Js.String.trim(word) != ""
    | None => false
    }
  }, Js.String.splitByRe(%re("/\\s+/"), s))
  Js.Json.number(Js.Int.toFloat(Js.Array.length(words)))
}

// ============= DATE FILTERS =============

let date: filterFunction = (. value, args) => {
  let format = getStringArg(args, 0, "iso")
  let d = switch Js.Json.classify(value) {
  | Js.Json.JSONNumber(n) => Js.Date.fromFloat(n)
  | Js.Json.JSONString(s) => Js.Date.fromString(s)
  | _ => Js.Date.make()
  }

  switch format {
  | "iso" => Js.Json.string(Js.Date.toISOString(d))
  | "date" => Js.Json.string(Js.Date.toDateString(d))
  | "time" => Js.Json.string(Js.Date.toTimeString(d))
  | "locale" => Js.Json.string(Js.Date.toLocaleString(d))
  | "year" => Js.Json.number(Js.Date.getFullYear(d))
  | "month" => Js.Json.number(Js.Date.getMonth(d) +. 1.0)
  | "day" => Js.Json.number(Js.Date.getDate(d))
  | _ => Js.Json.string(Js.Date.toISOString(d))
  }
}

// ============= REGISTER ALL FILTERS =============

let builtInFilters: Js.Dict.t<filterFunction> = {
  let d = Js.Dict.empty()

  // String filters
  Js.Dict.set(d, "upper", upper)
  Js.Dict.set(d, "lower", lower)
  Js.Dict.set(d, "capitalize", capitalize)
  Js.Dict.set(d, "title", title)
  Js.Dict.set(d, "trim", trim)
  Js.Dict.set(d, "ltrim", ltrim)
  Js.Dict.set(d, "rtrim", rtrim)
  Js.Dict.set(d, "truncate", truncate)
  Js.Dict.set(d, "wordwrap", wordwrap)
  Js.Dict.set(d, "center", center)
  Js.Dict.set(d, "pad", pad)
  Js.Dict.set(d, "replace", replace)
  Js.Dict.set(d, "replaceAll", replaceAll)
  Js.Dict.set(d, "split", split)
  Js.Dict.set(d, "striptags", striptags)
  Js.Dict.set(d, "nl2br", nl2br)
  Js.Dict.set(d, "urlEncode", urlEncode)
  Js.Dict.set(d, "urlDecode", urlDecode)

  // Array filters
  Js.Dict.set(d, "length", length)
  Js.Dict.set(d, "first", first)
  Js.Dict.set(d, "last", last)
  Js.Dict.set(d, "reverse", reverse)
  Js.Dict.set(d, "join", join)
  Js.Dict.set(d, "sort", sort)
  Js.Dict.set(d, "sortBy", sortBy)
  Js.Dict.set(d, "unique", unique)
  Js.Dict.set(d, "slice", slice)
  Js.Dict.set(d, "batch", batch)
  Js.Dict.set(d, "map", map)
  Js.Dict.set(d, "reject", reject)
  Js.Dict.set(d, "select", select)
  Js.Dict.set(d, "groupBy", groupBy)

  // Number filters
  Js.Dict.set(d, "abs", abs)
  Js.Dict.set(d, "round", round)
  Js.Dict.set(d, "floor", floor)
  Js.Dict.set(d, "ceil", ceil)
  Js.Dict.set(d, "fixed", fixed)
  Js.Dict.set(d, "formatNumber", formatNumber)

  // Utility filters
  Js.Dict.set(d, "default", default)
  Js.Dict.set(d, "safe", safe)
  Js.Dict.set(d, "escape", escape)
  Js.Dict.set(d, "e", escape) // Alias
  Js.Dict.set(d, "json", json)
  Js.Dict.set(d, "keys", keys)
  Js.Dict.set(d, "values", values)
  Js.Dict.set(d, "entries", entries)
  Js.Dict.set(d, "typeOf", typeOf)
  Js.Dict.set(d, "wordcount", wordcount)

  // Date filters
  Js.Dict.set(d, "date", date)

  d
}

// Get all built-in filter names
let filterNames = (): array<string> => Js.Dict.keys(builtInFilters)

// Get a filter by name
let getFilter = (name: string): option<filterFunction> => Js.Dict.get(builtInFilters, name)

// Merge custom filters with built-in ones
let mergeFilters = (custom: Js.Dict.t<filterFunction>): Js.Dict.t<filterFunction> => {
  let merged = Js.Dict.fromArray(Js.Dict.entries(builtInFilters))
  Js.Array.forEach(((key, value)) => Js.Dict.set(merged, key, value), Js.Dict.entries(custom))
  merged
}
