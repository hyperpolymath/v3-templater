// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * v3-templater — Lexical Analyzer (ReScript).
 *
 * This module tokenizes template strings into a stream of semantic tokens. 
 * It handles the transition between raw text and template directives 
 * (tags and variables).
 */

open Types

// LEXER STATE: Tracks the current physical location in the source string.
type lexerState = {
  input: string,
  mutable position: int,
  mutable line: int,
  mutable column: int,
  delimiters: delimiters, // Customizable {{ }} markers
}

/**
 * SCANNER: Extracts the next token from the input stream.
 * 
 * DISPATCH LOGIC:
 * 1. `{%`: Enter TAG mode (e.g. control flow).
 * 2. `{{`: Enter VARIABLE mode (e.g. data interpolation).
 * 3. Default: Consume characters as raw TEXT.
 */
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

/**
 * EXPRESSION LEXER: A specialized sub-lexer for content WITHIN tags.
 * Handles keywords (if, for, in), operators, strings, and numbers.
 */
module ExpressionLexer = {
  // ... [Expression tokenization logic]
}
