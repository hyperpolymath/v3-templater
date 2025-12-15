/**
 * Parser for v3-templater (ReScript)
 * Converts tokens from Lexer into AST nodes
 */

open Types

// Parser state
type parserState = {
  tokens: array<token>,
  mutable position: int,
}

// Create parser
let make = (tokens: array<token>): parserState => {
  {tokens: tokens, position: 0}
}

// Get current token
let current = (state: parserState): option<token> => {
  if state.position < Js.Array.length(state.tokens) {
    Some(state.tokens[state.position])
  } else {
    None
  }
}

// Peek at next token without consuming
let peek = (state: parserState): option<token> => {
  if state.position + 1 < Js.Array.length(state.tokens) {
    Some(state.tokens[state.position + 1])
  } else {
    None
  }
}

// Advance to next token
let advance = (state: parserState): unit => {
  state.position = state.position + 1
}

// Check if current token matches a type
let check = (state: parserState, type_: tokenType): bool => {
  switch current(state) {
  | Some(token) => token.type_ == type_
  | None => false
  }
}

// Consume token if it matches, otherwise error
let expect = (state: parserState, type_: tokenType): token => {
  switch current(state) {
  | Some(token) if token.type_ == type_ =>
    advance(state)
    token
  | Some(token) =>
    Js.Exn.raiseError(
      `Expected ${tokenTypeToString(type_)} but got ${tokenTypeToString(token.type_)} at line ${Belt.Int.toString(token.line)}`,
    )
  | None => Js.Exn.raiseError(`Unexpected end of input, expected ${tokenTypeToString(type_)}`)
  }
}

// Parse a primary expression (literals, variables, parenthesized)
let rec parsePrimary = (exprTokens: array<token>, pos: ref<int>): expression => {
  if pos.contents >= Js.Array.length(exprTokens) {
    LiteralExpr({value: Js.Json.null})
  } else {
    let token = exprTokens[pos.contents]
    switch token.type_ {
    | NUMBER =>
      pos := pos.contents + 1
      LiteralExpr({value: Js.Json.number(Js.Float.fromString(token.value))})
    | STRING =>
      pos := pos.contents + 1
      LiteralExpr({value: Js.Json.string(token.value)})
    | KEYWORD if token.value == "true" =>
      pos := pos.contents + 1
      LiteralExpr({value: Js.Json.boolean(true)})
    | KEYWORD if token.value == "false" =>
      pos := pos.contents + 1
      LiteralExpr({value: Js.Json.boolean(false)})
    | KEYWORD if token.value == "null" =>
      pos := pos.contents + 1
      LiteralExpr({value: Js.Json.null})
    | IDENTIFIER =>
      pos := pos.contents + 1
      let name = token.value
      // Check for member access
      parseMemberAccess(exprTokens, pos, VariableExpr({name: name}))
    | LPAREN =>
      pos := pos.contents + 1
      let expr = parseExpression(exprTokens, pos)
      // Expect closing paren
      if pos.contents < Js.Array.length(exprTokens) && exprTokens[pos.contents].type_ == RPAREN {
        pos := pos.contents + 1
      }
      expr
    | OPERATOR if token.value == "-" || token.value == "!" =>
      pos := pos.contents + 1
      let arg = parsePrimary(exprTokens, pos)
      UnaryExpr({operator: token.value, argument: arg})
    | KEYWORD if token.value == "not" =>
      pos := pos.contents + 1
      let arg = parsePrimary(exprTokens, pos)
      UnaryExpr({operator: "not", argument: arg})
    | _ => LiteralExpr({value: Js.Json.null})
    }
  }
}

// Parse member access (obj.prop or obj[index])
and parseMemberAccess = (
  exprTokens: array<token>,
  pos: ref<int>,
  obj: expression,
): expression => {
  if pos.contents >= Js.Array.length(exprTokens) {
    obj
  } else {
    let token = exprTokens[pos.contents]
    switch token.type_ {
    | DOT =>
      pos := pos.contents + 1
      if pos.contents < Js.Array.length(exprTokens) {
        let propToken = exprTokens[pos.contents]
        if propToken.type_ == IDENTIFIER || propToken.type_ == NUMBER {
          pos := pos.contents + 1
          let newExpr = MemberExpr({object: obj, property: propToken.value})
          parseMemberAccess(exprTokens, pos, newExpr)
        } else {
          obj
        }
      } else {
        obj
      }
    | LBRACKET =>
      pos := pos.contents + 1
      let indexExpr = parseExpression(exprTokens, pos)
      // Expect closing bracket
      if pos.contents < Js.Array.length(exprTokens) && exprTokens[pos.contents].type_ == RBRACKET {
        pos := pos.contents + 1
      }
      // Convert index expression to member access if it's a literal
      let property = switch indexExpr {
      | LiteralExpr({value}) =>
        switch Js.Json.decodeString(value) {
        | Some(s) => s
        | None =>
          switch Js.Json.decodeNumber(value) {
          | Some(n) => Js.Float.toString(n)
          | None => "0"
          }
        }
      | _ => "0"
      }
      let newExpr = MemberExpr({object: obj, property: property})
      parseMemberAccess(exprTokens, pos, newExpr)
    | LPAREN =>
      // Function call
      pos := pos.contents + 1
      let args = parseArguments(exprTokens, pos)
      let newExpr = CallExpr({callee: obj, arguments: args})
      parseMemberAccess(exprTokens, pos, newExpr)
    | _ => obj
    }
  }
}

// Parse function arguments
and parseArguments = (exprTokens: array<token>, pos: ref<int>): array<expression> => {
  let args = []
  let continue = ref(true)

  while continue.contents && pos.contents < Js.Array.length(exprTokens) {
    let token = exprTokens[pos.contents]
    if token.type_ == RPAREN {
      pos := pos.contents + 1
      continue := false
    } else {
      let arg = parseExpression(exprTokens, pos)
      let _ = Js.Array.push(arg, args)
      // Check for comma
      if pos.contents < Js.Array.length(exprTokens) && exprTokens[pos.contents].type_ == COMMA {
        pos := pos.contents + 1
      }
    }
  }
  args
}

// Parse multiplicative expressions (*, /, %)
and parseMultiplicative = (exprTokens: array<token>, pos: ref<int>): expression => {
  let left = ref(parsePrimary(exprTokens, pos))

  while pos.contents < Js.Array.length(exprTokens) {
    let token = exprTokens[pos.contents]
    if token.type_ == OPERATOR && (token.value == "*" || token.value == "/" || token.value == "%") {
      pos := pos.contents + 1
      let right = parsePrimary(exprTokens, pos)
      left := BinaryExpr({operator: token.value, left: left.contents, right: right})
    } else {
      break
    }
  }
  left.contents
}

// Parse additive expressions (+, -)
and parseAdditive = (exprTokens: array<token>, pos: ref<int>): expression => {
  let left = ref(parseMultiplicative(exprTokens, pos))

  while pos.contents < Js.Array.length(exprTokens) {
    let token = exprTokens[pos.contents]
    if token.type_ == OPERATOR && (token.value == "+" || token.value == "-") {
      pos := pos.contents + 1
      let right = parseMultiplicative(exprTokens, pos)
      left := BinaryExpr({operator: token.value, left: left.contents, right: right})
    } else {
      break
    }
  }
  left.contents
}

// Parse comparison expressions (<, >, <=, >=)
and parseComparison = (exprTokens: array<token>, pos: ref<int>): expression => {
  let left = ref(parseAdditive(exprTokens, pos))

  while pos.contents < Js.Array.length(exprTokens) {
    let token = exprTokens[pos.contents]
    if (
      token.type_ == OPERATOR &&
      (token.value == "<" ||
      token.value == ">" ||
      token.value == "<=" ||
      token.value == ">=")
    ) {
      pos := pos.contents + 1
      let right = parseAdditive(exprTokens, pos)
      left := BinaryExpr({operator: token.value, left: left.contents, right: right})
    } else {
      break
    }
  }
  left.contents
}

// Parse equality expressions (==, !=)
and parseEquality = (exprTokens: array<token>, pos: ref<int>): expression => {
  let left = ref(parseComparison(exprTokens, pos))

  while pos.contents < Js.Array.length(exprTokens) {
    let token = exprTokens[pos.contents]
    if token.type_ == OPERATOR && (token.value == "==" || token.value == "!=") {
      pos := pos.contents + 1
      let right = parseComparison(exprTokens, pos)
      left := BinaryExpr({operator: token.value, left: left.contents, right: right})
    } else {
      break
    }
  }
  left.contents
}

// Parse logical AND expressions
and parseLogicalAnd = (exprTokens: array<token>, pos: ref<int>): expression => {
  let left = ref(parseEquality(exprTokens, pos))

  while pos.contents < Js.Array.length(exprTokens) {
    let token = exprTokens[pos.contents]
    if token.type_ == KEYWORD && token.value == "and" {
      pos := pos.contents + 1
      let right = parseEquality(exprTokens, pos)
      left := BinaryExpr({operator: "and", left: left.contents, right: right})
    } else {
      break
    }
  }
  left.contents
}

// Parse logical OR expressions
and parseLogicalOr = (exprTokens: array<token>, pos: ref<int>): expression => {
  let left = ref(parseLogicalAnd(exprTokens, pos))

  while pos.contents < Js.Array.length(exprTokens) {
    let token = exprTokens[pos.contents]
    if token.type_ == KEYWORD && token.value == "or" {
      pos := pos.contents + 1
      let right = parseLogicalAnd(exprTokens, pos)
      left := BinaryExpr({operator: "or", left: left.contents, right: right})
    } else {
      break
    }
  }
  left.contents
}

// Main expression parser
and parseExpression = (exprTokens: array<token>, pos: ref<int>): expression => {
  parseLogicalOr(exprTokens, pos)
}

// Parse expression from string using ExpressionLexer
let parseExpressionString = (input: string): expression => {
  let lexer = Lexer.ExpressionLexer.make(input)
  let tokens = Lexer.ExpressionLexer.tokenize(lexer)
  let pos = ref(0)
  parseExpression(tokens, pos)
}

// Parse variable with optional filters: name | filter1 | filter2(arg)
let parseVariableWithFilters = (content: string): variableNode => {
  let parts = Js.String.split("|", content)
  let namePart = Js.String.trim(parts[0])

  let filters = []
  for i in 1 to Js.Array.length(parts) - 1 {
    let filterPart = Js.String.trim(parts[i])
    // Check for filter arguments: filter(arg1, arg2)
    let parenIndex = Js.String.indexOf("(", filterPart)
    if parenIndex > 0 {
      let filterName = Js.String.substring(~from=0, ~to_=parenIndex, filterPart)
      let argsStr = Js.String.substring(
        ~from=parenIndex + 1,
        ~to_=Js.String.length(filterPart) - 1,
        filterPart,
      )
      let argParts = Js.String.split(",", argsStr)
      let args = Js.Array.map(arg => {
        let trimmed = Js.String.trim(arg)
        // Try to parse as number
        let num = Js.Float.fromString(trimmed)
        if Js.Float.isNaN(num) {
          // It's a string - remove quotes if present
          if (
            (Js.String.startsWith("\"", trimmed) || Js.String.startsWith("'", trimmed)) &&
              Js.String.length(trimmed) > 2
          ) {
            Js.Json.string(Js.String.substring(~from=1, ~to_=Js.String.length(trimmed) - 1, trimmed))
          } else {
            Js.Json.string(trimmed)
          }
        } else {
          Js.Json.number(num)
        }
      }, argParts)
      let _ = Js.Array.push({name: filterName, args: args}, filters)
    } else {
      let _ = Js.Array.push({name: filterPart, args: []}, filters)
    }
  }

  {name: namePart, filters: filters}
}

// Parse tag content to extract keyword and rest
let parseTagContent = (content: string): (string, string) => {
  let trimmed = Js.String.trim(content)
  let spaceIndex = Js.String.indexOf(" ", trimmed)
  if spaceIndex > 0 {
    let keyword = Js.String.substring(~from=0, ~to_=spaceIndex, trimmed)
    let rest = Js.String.trim(Js.String.substringToEnd(~from=spaceIndex + 1, trimmed))
    (keyword, rest)
  } else {
    (trimmed, "")
  }
}

// Parse for loop: "item in items" or "key, value in object"
let parseForLoop = (content: string): (string, option<string>, expression) => {
  let inIndex = Js.String.indexOf(" in ", content)
  if inIndex > 0 {
    let varPart = Js.String.trim(Js.String.substring(~from=0, ~to_=inIndex, content))
    let iterablePart = Js.String.trim(Js.String.substringToEnd(~from=inIndex + 4, content))

    // Check for "key, value" pattern
    let commaIndex = Js.String.indexOf(",", varPart)
    if commaIndex > 0 {
      let indexVar = Js.String.trim(Js.String.substring(~from=0, ~to_=commaIndex, varPart))
      let valueVar = Js.String.trim(Js.String.substringToEnd(~from=commaIndex + 1, varPart))
      (valueVar, Some(indexVar), parseExpressionString(iterablePart))
    } else {
      (varPart, None, parseExpressionString(iterablePart))
    }
  } else {
    ("item", None, VariableExpr({name: "items"}))
  }
}

// Main parser - parse all tokens into AST
let rec parse = (state: parserState): array<astNode> => {
  let nodes = []

  while state.position < Js.Array.length(state.tokens) {
    switch current(state) {
    | Some(token) =>
      switch token.type_ {
      | EOF => advance(state)
      | TEXT =>
        if token.value != "" {
          let _ = Js.Array.push(TextNode({value: token.value}), nodes)
        }
        advance(state)
      | VARIABLE_START =>
        let varNode = parseVariableWithFilters(token.value)
        let _ = Js.Array.push(VariableNode(varNode), nodes)
        advance(state)
      | TAG_START =>
        let (keyword, rest) = parseTagContent(token.value)
        switch keyword {
        | "if" =>
          advance(state)
          let ifNode = parseIf(state, rest)
          let _ = Js.Array.push(IfNode(ifNode), nodes)
        | "for" =>
          advance(state)
          let forNode = parseFor(state, rest)
          let _ = Js.Array.push(ForNode(forNode), nodes)
        | "block" =>
          advance(state)
          let blockNode = parseBlock(state, rest)
          let _ = Js.Array.push(BlockNode(blockNode), nodes)
        | "extends" =>
          let parent = parseStringLiteral(rest)
          let _ = Js.Array.push(ExtendsNode({parent: parent}), nodes)
          advance(state)
        | "include" =>
          let template = parseStringLiteral(rest)
          let _ = Js.Array.push(IncludeNode({template: template, context: None}), nodes)
          advance(state)
        | "endif" | "endfor" | "endblock" | "else" | "elif" =>
          // End tags are handled by parent parsers
          break
        | _ =>
          // Unknown tag, treat as text
          advance(state)
        }
      | _ => advance(state)
      }
    | None => break
    }
  }
  nodes
}

// Parse if statement
and parseIf = (state: parserState, conditionStr: string): ifNode => {
  let condition = parseExpressionString(conditionStr)
  let consequent = []
  let alternate = ref(None)
  let elseIfs = ref([])

  // Parse body until endif, else, or elif
  while state.position < Js.Array.length(state.tokens) {
    switch current(state) {
    | Some(token) =>
      switch token.type_ {
      | TAG_START =>
        let (keyword, rest) = parseTagContent(token.value)
        switch keyword {
        | "endif" =>
          advance(state)
          break
        | "else" =>
          advance(state)
          let elseBody = parseElseBody(state)
          alternate := Some(elseBody)
          break
        | "elif" =>
          advance(state)
          let elifBranches = parseElif(state, rest, [])
          elseIfs := elifBranches
          break
        | _ =>
          let children = parse(state)
          Js.Array.forEach(child => {
            let _ = Js.Array.push(child, consequent)
          }, children)
        }
      | EOF => break
      | _ =>
        let children = parse(state)
        Js.Array.forEach(child => {
          let _ = Js.Array.push(child, consequent)
        }, children)
      }
    | None => break
    }
  }

  {
    condition: condition,
    consequent: consequent,
    alternate: alternate.contents,
    elseIfs: if Js.Array.length(elseIfs.contents) > 0 {
      Some(elseIfs.contents)
    } else {
      None
    },
  }
}

// Parse else body
and parseElseBody = (state: parserState): array<astNode> => {
  let body = []

  while state.position < Js.Array.length(state.tokens) {
    switch current(state) {
    | Some(token) =>
      switch token.type_ {
      | TAG_START =>
        let (keyword, _) = parseTagContent(token.value)
        if keyword == "endif" {
          advance(state)
          break
        } else {
          let children = parse(state)
          Js.Array.forEach(child => {
            let _ = Js.Array.push(child, body)
          }, children)
        }
      | EOF => break
      | _ =>
        let children = parse(state)
        Js.Array.forEach(child => {
          let _ = Js.Array.push(child, body)
        }, children)
      }
    | None => break
    }
  }
  body
}

// Parse elif branches
and parseElif = (
  state: parserState,
  conditionStr: string,
  branches: array<elseIfBranch>,
): array<elseIfBranch> => {
  let condition = parseExpressionString(conditionStr)
  let body = []

  while state.position < Js.Array.length(state.tokens) {
    switch current(state) {
    | Some(token) =>
      switch token.type_ {
      | TAG_START =>
        let (keyword, rest) = parseTagContent(token.value)
        switch keyword {
        | "endif" =>
          advance(state)
          let _ = Js.Array.push({condition: condition, body: body}, branches)
          break
        | "else" =>
          advance(state)
          let _ = Js.Array.push({condition: condition, body: body}, branches)
          break
        | "elif" =>
          advance(state)
          let _ = Js.Array.push({condition: condition, body: body}, branches)
          return parseElif(state, rest, branches)
        | _ =>
          let children = parse(state)
          Js.Array.forEach(child => {
            let _ = Js.Array.push(child, body)
          }, children)
        }
      | EOF => break
      | _ =>
        let children = parse(state)
        Js.Array.forEach(child => {
          let _ = Js.Array.push(child, body)
        }, children)
      }
    | None => break
    }
  }

  let _ = Js.Array.push({condition: condition, body: body}, branches)
  branches
}

// Parse for loop
and parseFor = (state: parserState, loopDef: string): forNode => {
  let (variable, indexVar, iterable) = parseForLoop(loopDef)
  let body = []

  while state.position < Js.Array.length(state.tokens) {
    switch current(state) {
    | Some(token) =>
      switch token.type_ {
      | TAG_START =>
        let (keyword, _) = parseTagContent(token.value)
        if keyword == "endfor" {
          advance(state)
          break
        } else {
          let children = parse(state)
          Js.Array.forEach(child => {
            let _ = Js.Array.push(child, body)
          }, children)
        }
      | EOF => break
      | _ =>
        let children = parse(state)
        Js.Array.forEach(child => {
          let _ = Js.Array.push(child, body)
        }, children)
      }
    | None => break
    }
  }

  {variable: variable, iterable: iterable, body: body, indexVar: indexVar}
}

// Parse block
and parseBlock = (state: parserState, blockName: string): blockNode => {
  let name = Js.String.trim(blockName)
  let body = []

  while state.position < Js.Array.length(state.tokens) {
    switch current(state) {
    | Some(token) =>
      switch token.type_ {
      | TAG_START =>
        let (keyword, _) = parseTagContent(token.value)
        if keyword == "endblock" {
          advance(state)
          break
        } else {
          let children = parse(state)
          Js.Array.forEach(child => {
            let _ = Js.Array.push(child, body)
          }, children)
        }
      | EOF => break
      | _ =>
        let children = parse(state)
        Js.Array.forEach(child => {
          let _ = Js.Array.push(child, body)
        }, children)
      }
    | None => break
    }
  }

  {name: name, body: body}
}

// Parse string literal (remove quotes)
and parseStringLiteral = (str: string): string => {
  let trimmed = Js.String.trim(str)
  if (
    (Js.String.startsWith("\"", trimmed) || Js.String.startsWith("'", trimmed)) &&
      Js.String.length(trimmed) > 2
  ) {
    Js.String.substring(~from=1, ~to_=Js.String.length(trimmed) - 1, trimmed)
  } else {
    trimmed
  }
}

// Public API: Parse template string into AST
let parseTemplate = (template: string, delimiters: option<delimiters>): array<astNode> => {
  let lexer = Lexer.make(template, delimiters)
  let tokens = Lexer.tokenize(lexer)
  let parser = make(tokens)
  parse(parser)
}
