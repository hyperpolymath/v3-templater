/**
 * v3-templater — Core Type Definitions (ReScript).
 *
 * This module defines the semantic domain model for the template engine. 
 * It covers the configuration, AST structure, and token types used 
 * throughout the Lexer, Parser, and Compiler.
 */

// CONFIGURATION: Parameters for template evaluation and delimiters.
type delimiters = { start: string, end_: string }

type templateOptions = {
  delimiters: option<delimiters>,
  autoEscape: option<bool>, // Enable/disable automatic HTML escaping
  strictMode: option<bool>, // Throw errors on missing variables
  cache: option<bool>,      // Memoize compiled templates
}

// AST: The Abstract Syntax Tree representing a parsed template.
and astNode =
  | TextNode(textNode)         // Raw character data
  | VariableNode(variableNode) // {{ data }} interpolation
  | IfNode(ifNode)             // {% if ... %} conditional
  | ForNode(forNode)           // {% for ... %} iteration
  | IncludeNode(includeNode)   // {% include "..." %} partials
  | BlockNode(blockNode)       // {% block ... %} inheritance
  | ExtendsNode(extendsNode)   // {% extends "..." %} inheritance

// EXPRESSIONS: Logical and mathematical constructs within tags.
and expression =
  | LiteralExpr(literalExpression)   // Numbers, Strings, Booleans
  | VariableExpr(variableExpression) // Identifier lookup
  | BinaryExpr(binaryExpression)     // a + b, x == y
  | UnaryExpr(unaryExpression)       // !flag, -n
  | MemberExpr(memberExpression)     // object.property

// TOKENS: Atomic units produced by the Lexer.
type tokenType =
  | TEXT | TAG_START | TAG_END | VARIABLE_START | VARIABLE_END
  | IDENTIFIER | NUMBER | STRING | OPERATOR | KEYWORD | EOF
