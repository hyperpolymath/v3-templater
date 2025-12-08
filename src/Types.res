/**
 * Core type definitions for v3-templater (ReScript)
 */

// Template configuration
type delimiters = {
  start: string,
  end_: string,
}

type templateOptions = {
  delimiters: option<delimiters>,
  autoEscape: option<bool>,
  strictMode: option<bool>,
  cache: option<bool>,
  filters: option<Js.Dict.t<filterFunction>>,
  helpers: option<Js.Dict.t<helperFunction>>,
  plugins: option<array<plugin>>,
}

and filterFunction = (. Js.Json.t, array<Js.Json.t>) => Js.Json.t
and helperFunction = (. array<Js.Json.t>) => Js.Json.t

and plugin = {
  name: string,
  install: (. Js.t<{..}>) => unit,
}

// Compiled template
type compiledTemplate = {
  render: (. Js.Dict.t<Js.Json.t>) => string,
  source: string,
  ast: astNode,
}

// AST Node types
and astNode =
  | TextNode(textNode)
  | VariableNode(variableNode)
  | IfNode(ifNode)
  | ForNode(forNode)
  | IncludeNode(includeNode)
  | BlockNode(blockNode)
  | ExtendsNode(extendsNode)
  | FilterNode(filterNode)

and textNode = {value: string}

and variableNode = {
  name: string,
  filters: array<filterCall>,
}

and filterCall = {
  name: string,
  args: array<Js.Json.t>,
}

and ifNode = {
  condition: expression,
  consequent: array<astNode>,
  alternate: option<array<astNode>>,
  elseIfs: option<array<elseIfBranch>>,
}

and elseIfBranch = {
  condition: expression,
  body: array<astNode>,
}

and forNode = {
  variable: string,
  iterable: expression,
  body: array<astNode>,
  indexVar: option<string>,
}

and includeNode = {
  template: string,
  context: option<Js.Dict.t<Js.Json.t>>,
}

and blockNode = {
  name: string,
  body: array<astNode>,
}

and extendsNode = {parent: string}

and filterNode = {
  name: string,
  args: array<expression>,
}

// Expression types
and expression =
  | LiteralExpr(literalExpression)
  | VariableExpr(variableExpression)
  | BinaryExpr(binaryExpression)
  | UnaryExpr(unaryExpression)
  | CallExpr(callExpression)
  | MemberExpr(memberExpression)

and literalExpression = {value: Js.Json.t}

and variableExpression = {name: string}

and binaryExpression = {
  operator: string,
  left: expression,
  right: expression,
}

and unaryExpression = {
  operator: string,
  argument: expression,
}

and callExpression = {
  callee: expression,
  arguments: array<expression>,
}

and memberExpression = {
  object: expression,
  property: string,
}

// Token types
type tokenType =
  | TEXT
  | TAG_START
  | TAG_END
  | VARIABLE_START
  | VARIABLE_END
  | IDENTIFIER
  | NUMBER
  | STRING
  | OPERATOR
  | KEYWORD
  | DOT
  | COMMA
  | PIPE
  | LPAREN
  | RPAREN
  | LBRACKET
  | RBRACKET
  | EOF

type token = {
  type_: tokenType,
  value: string,
  line: int,
  column: int,
}

// Default options
let defaultDelimiters = {start: "{{", end_: "}}"}

let defaultOptions: templateOptions = {
  delimiters: Some(defaultDelimiters),
  autoEscape: Some(true),
  strictMode: Some(false),
  cache: Some(true),
  filters: None,
  helpers: None,
  plugins: None,
}

// Token type to string
let tokenTypeToString = (tt: tokenType): string =>
  switch tt {
  | TEXT => "TEXT"
  | TAG_START => "TAG_START"
  | TAG_END => "TAG_END"
  | VARIABLE_START => "VARIABLE_START"
  | VARIABLE_END => "VARIABLE_END"
  | IDENTIFIER => "IDENTIFIER"
  | NUMBER => "NUMBER"
  | STRING => "STRING"
  | OPERATOR => "OPERATOR"
  | KEYWORD => "KEYWORD"
  | DOT => "DOT"
  | COMMA => "COMMA"
  | PIPE => "PIPE"
  | LPAREN => "LPAREN"
  | RPAREN => "RPAREN"
  | LBRACKET => "LBRACKET"
  | RBRACKET => "RBRACKET"
  | EOF => "EOF"
  }
