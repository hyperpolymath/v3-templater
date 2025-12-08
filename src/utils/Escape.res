/**
 * HTML escaping utilities for XSS protection (ReScript)
 */

// HTML entity mappings
let htmlEntities = Js.Dict.fromArray([
  ("&", "&amp;"),
  ("<", "&lt;"),
  (">", "&gt;"),
  ("\"", "&quot;"),
  ("'", "&#x27;"),
  ("/", "&#x2F;"),
])

// Escape a single character
let escapeChar = (ch: string): string => {
  switch Js.Dict.get(htmlEntities, ch) {
  | Some(entity) => entity
  | None => ch
  }
}

// Escape HTML entities to prevent XSS attacks
let escapeHtml = (str: string): string => {
  let chars = Js.String.split("", str)
  let escaped = Js.Array.map(ch => {
    if Js.Re.test_(%re("/[&<>\"'\/]/"), ch) {
      escapeChar(ch)
    } else {
      ch
    }
  }, chars)
  Js.Array.joinWith("", escaped)
}

// SafeString type - marks content as already escaped
module SafeString = {
  type t = {value: string}

  let make = (value: string): t => {value: value}

  let toString = (safe: t): string => safe.value

  let isSafeString = (value: 'a): bool => {
    // Check if value has a 'value' property (duck typing)
    Js.typeof(value) == "object" &&
      !Js.Nullable.isNullable(value) &&
      Js.Dict.get(Obj.magic(value), "value")->Belt.Option.isSome
  }
}

// Ensure value is properly escaped unless marked as safe
let ensureSafe = (value: Js.Json.t, autoEscape: bool): string => {
  // Try to treat as SafeString first
  let maybeSafe = try {
    let obj = Js.Json.decodeObject(value)
    switch obj {
    | Some(dict) =>
      switch Js.Dict.get(dict, "value") {
      | Some(v) =>
        switch Js.Json.decodeString(v) {
        | Some(str) => Some(str)
        | None => None
        }
      | None => None
      }
    | None => None
    }
  } catch {
  | _ => None
  }

  switch maybeSafe {
  | Some(safeValue) => safeValue
  | None =>
    // Convert to string and escape if needed
    let strValue = switch Js.Json.classify(value) {
    | Js.Json.JSONString(s) => s
    | Js.Json.JSONNumber(n) => Js.Float.toString(n)
    | Js.Json.JSONTrue => "true"
    | Js.Json.JSONFalse => "false"
    | Js.Json.JSONNull => ""
    | Js.Json.JSONObject(_) => "[object Object]"
    | Js.Json.JSONArray(_) => "[array]"
    }
    autoEscape ? escapeHtml(strValue) : strValue
  }
}

// Convert any value to string safely
let valueToString = (value: Js.Json.t): string => {
  switch Js.Json.classify(value) {
  | Js.Json.JSONString(s) => s
  | Js.Json.JSONNumber(n) => Js.Float.toString(n)
  | Js.Json.JSONTrue => "true"
  | Js.Json.JSONFalse => "false"
  | Js.Json.JSONNull => ""
  | Js.Json.JSONObject(_) => Js.Json.stringify(value)
  | Js.Json.JSONArray(_) => Js.Json.stringify(value)
  }
}
