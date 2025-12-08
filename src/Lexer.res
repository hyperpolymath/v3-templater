/**
 * Lexical analyzer for v3-templater (ReScript)
 * Converts template strings into tokens
 */

open Types

// Lexer state
type lexerState = {
  input: string,
  mutable position: int,
  mutable line: int,
  mutable column: int,
  delimiters: delimiters,
}

// Create lexer
let make = (input: string, delimiters: option<delimiters>): lexerState => {
  let d = switch delimiters {
  | Some(d) => d
  | None => {start: "{{", end_: "}}"}
  }
  {input: input, position: 0, line: 1, column: 1, delimiters: d}
}

// Get current character
let current = (state: lexerState): option<string> => {
  if state.position < Js.String.length(state.input) {
    Some(Js.String.charAt(state.position, state.input))
  } else {
    None
  }
}

// Check if string at current position matches
let peek = (state: lexerState, str: string): bool => {
  let substr = Js.String.substring(
    ~from=state.position,
    ~to_=state.position + Js.String.length(str),
    state.input,
  )
  substr == str
}

// Advance position by n characters
let rec advance = (state: lexerState, n: int): unit => {
  if n > 0 {
    switch current(state) {
    | Some(ch) =>
      if ch == "\n" {
        state.line = state.line + 1
        state.column = 1
      } else {
        state.column = state.column + 1
      }
      state.position = state.position + 1
      advance(state, n - 1)
    | None => ()
    }
  }
}

// Skip whitespace
let rec skipWhitespace = (state: lexerState): unit => {
  switch current(state) {
  | Some(ch) if Js.Re.test_(%re("/\\s/"), ch) =>
    advance(state, 1)
    skipWhitespace(state)
  | _ => ()
  }
}

// Read until a specific string is found
let readUntil = (state: lexerState, str: string): string => {
  let rec loop = (acc: string): string => {
    if state.position < Js.String.length(state.input) && !peek(state, str) {
      switch current(state) {
      | Some(ch) =>
        advance(state, 1)
        loop(acc ++ ch)
      | None => acc
      }
    } else {
      acc
    }
  }
  loop("")
}

// Create token
let createToken = (state: lexerState, type_: tokenType, value: string): token => {
  {type_: type_, value: value, line: state.line, column: state.column}
}

// Read text until next delimiter
let readText = (state: lexerState): token => {
  let rec loop = (text: string): string => {
    if state.position < Js.String.length(state.input) {
      if peek(state, "{%") || peek(state, state.delimiters.start) {
        text
      } else {
        switch current(state) {
        | Some(ch) =>
          advance(state, 1)
          loop(text ++ ch)
        | None => text
        }
      }
    } else {
      text
    }
  }
  createToken(state, TEXT, loop(""))
}

// Read a tag block {% ... %}
let readTag = (state: lexerState): token => {
  advance(state, 2) // skip '{%'
  skipWhitespace(state)
  let content = readUntil(state, "%}")
  advance(state, 2) // skip '%}'
  createToken(state, TAG_START, Js.String.trim(content))
}

// Read a variable block {{ ... }}
let readVariable = (state: lexerState): token => {
  let startLen = Js.String.length(state.delimiters.start)
  let endLen = Js.String.length(state.delimiters.end_)

  advance(state, startLen)
  skipWhitespace(state)
  let content = readUntil(state, state.delimiters.end_)
  advance(state, endLen)
  createToken(state, VARIABLE_START, Js.String.trim(content))
}

// Get next token
let nextToken = (state: lexerState): option<token> => {
  if state.position >= Js.String.length(state.input) {
    Some(createToken(state, EOF, ""))
  } else if peek(state, "{%") {
    Some(readTag(state))
  } else if peek(state, state.delimiters.start) {
    Some(readVariable(state))
  } else {
    Some(readText(state))
  }
}

// Tokenize entire input
let tokenize = (state: lexerState): array<token> => {
  let rec loop = (tokens: array<token>): array<token> => {
    switch nextToken(state) {
    | Some(token) =>
      let newTokens = Js.Array.concat([token], tokens)
      if token.type_ == EOF {
        newTokens
      } else {
        loop(newTokens)
      }
    | None => tokens
    }
  }
  Js.Array.reverseInPlace(loop([]))
}

// Expression Lexer for tag content tokenization
module ExpressionLexer = {
  type state = {
    input: string,
    mutable position: int,
  }

  let make = (input: string): state => {
    {input: Js.String.trim(input), position: 0}
  }

  let current = (state: state): option<string> => {
    if state.position < Js.String.length(state.input) {
      Some(Js.String.charAt(state.position, state.input))
    } else {
      None
    }
  }

  let advance = (state: state, n: int): unit => {
    state.position = state.position + n
  }

  let rec skipWhitespace = (state: state): unit => {
    switch current(state) {
    | Some(ch) if Js.Re.test_(%re("/\\s/"), ch) =>
      advance(state, 1)
      skipWhitespace(state)
    | _ => ()
    }
  }

  let readOperator = (state: state): token => {
    switch current(state) {
    | Some(ch) =>
      let op = ref(ch)
      advance(state, 1)
      switch current(state) {
      | Some("=") =>
        op := op.contents ++ "="
        advance(state, 1)
      | _ => ()
      }
      {type_: OPERATOR, value: op.contents, line: 1, column: state.position}
    | None => {type_: EOF, value: "", line: 1, column: state.position}
    }
  }

  let readNumber = (state: state): token => {
    let rec loop = (num: string): string => {
      switch current(state) {
      | Some(ch) if Js.Re.test_(%re("/[\\d.]/"), ch) =>
        advance(state, 1)
        loop(num ++ ch)
      | _ => num
      }
    }
    {type_: NUMBER, value: loop(""), line: 1, column: state.position}
  }

  let readString = (state: state): token => {
    let quote = switch current(state) {
    | Some(q) => q
    | None => "\""
    }
    advance(state, 1) // skip opening quote

    let rec loop = (str: string): string => {
      switch current(state) {
      | Some(ch) if ch == quote => str
      | Some("\\") =>
        advance(state, 1)
        switch current(state) {
        | Some(escaped) =>
          advance(state, 1)
          loop(str ++ escaped)
        | None => str
        }
      | Some(ch) =>
        advance(state, 1)
        loop(str ++ ch)
      | None => str
      }
    }

    let str = loop("")
    advance(state, 1) // skip closing quote
    {type_: STRING, value: str, line: 1, column: state.position}
  }

  let readIdentifier = (state: state): token => {
    let rec loop = (ident: string): string => {
      switch current(state) {
      | Some(ch) if Js.Re.test_(%re("/[a-zA-Z0-9_]/"), ch) =>
        advance(state, 1)
        loop(ident ++ ch)
      | _ => ident
      }
    }

    let ident = loop("")
    let keywords = [
      "if",
      "else",
      "elif",
      "endif",
      "for",
      "endfor",
      "in",
      "block",
      "endblock",
      "extends",
      "include",
      "true",
      "false",
      "null",
      "and",
      "or",
      "not",
    ]
    let type_ = Js.Array.includes(ident, keywords) ? KEYWORD : IDENTIFIER
    {type_: type_, value: ident, line: 1, column: state.position}
  }

  let nextToken = (state: state): option<token> => {
    switch current(state) {
    | Some(ch) if Js.String.includes("=!<>", ch) => Some(readOperator(state))
    | Some(ch) if Js.Re.test_(%re("/\\d/"), ch) => Some(readNumber(state))
    | Some(ch) if ch == "\"" || ch == "'" => Some(readString(state))
    | Some(ch) if Js.Re.test_(%re("/[a-zA-Z_]/"), ch) => Some(readIdentifier(state))
    | Some(".") =>
      advance(state, 1)
      Some({type_: DOT, value: ".", line: 1, column: state.position})
    | Some(",") =>
      advance(state, 1)
      Some({type_: COMMA, value: ",", line: 1, column: state.position})
    | Some("|") =>
      advance(state, 1)
      Some({type_: PIPE, value: "|", line: 1, column: state.position})
    | Some("(") =>
      advance(state, 1)
      Some({type_: LPAREN, value: "(", line: 1, column: state.position})
    | Some(")") =>
      advance(state, 1)
      Some({type_: RPAREN, value: ")", line: 1, column: state.position})
    | Some("[") =>
      advance(state, 1)
      Some({type_: LBRACKET, value: "[", line: 1, column: state.position})
    | Some("]") =>
      advance(state, 1)
      Some({type_: RBRACKET, value: "]", line: 1, column: state.position})
    | Some(ch) if Js.String.includes("+-*/%", ch) =>
      advance(state, 1)
      Some({type_: OPERATOR, value: ch, line: 1, column: state.position})
    | Some(_) =>
      advance(state, 1)
      None
    | None => None
    }
  }

  let tokenize = (state: state): array<token> => {
    let rec loop = (tokens: array<token>): array<token> => {
      skipWhitespace(state)
      if state.position >= Js.String.length(state.input) {
        tokens
      } else {
        switch nextToken(state) {
        | Some(token) => loop(Js.Array.concat([token], tokens))
        | None => loop(tokens)
        }
      }
    }
    let tokens = Js.Array.reverseInPlace(loop([]))
    Js.Array.concat([{type_: EOF, value: "", line: 1, column: state.position}], tokens)
  }
}
