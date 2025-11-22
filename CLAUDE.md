# v3-templater

## Project Overview

v3-templater is a modern, secure, and high-performance templating engine for Node.js with full TypeScript support. Built from scratch with security and developer experience as top priorities.

## Project Structure

```
v3-templater/
├── CLAUDE.md                 # This file - project context for Claude
├── README.md                 # Comprehensive user documentation
├── CONTRIBUTING.md           # Contributing guidelines
├── CHANGELOG.md              # Version history
├── LICENSE                   # MIT License
├── package.json              # Dependencies and scripts
├── tsconfig.json             # TypeScript configuration
├── jest.config.js            # Jest test configuration
├── .eslintrc.js              # ESLint configuration
├── .prettierrc               # Prettier formatting rules
├── src/
│   ├── index.ts              # Main export file
│   ├── types.ts              # TypeScript type definitions
│   ├── lexer.ts              # Tokenization (template → tokens)
│   ├── parser.ts             # Parsing (tokens → AST)
│   ├── compiler.ts           # Compilation (AST → executable)
│   ├── runtime.ts            # Expression evaluation
│   ├── template.ts           # Main Template class (sync)
│   ├── async-template.ts     # AsyncTemplate class
│   ├── filters.ts            # 30+ built-in filters
│   ├── cache.ts              # LRU template cache
│   ├── cli.ts                # Command-line tool
│   ├── benchmark.ts          # Performance benchmarks
│   ├── utils/
│   │   └── escape.ts         # HTML escaping & SafeString
│   └── __tests__/            # Unit tests (5 files)
├── docs/
│   ├── API.md                # Complete API documentation
│   └── MIGRATION.md          # Migration guides from other engines
├── examples/
│   ├── basic.js              # Basic usage examples
│   ├── email-template.html   # Professional email template
│   ├── blog-template.html    # Blog post template
│   ├── dashboard-template.html # Analytics dashboard
│   ├── email-data.json       # Sample data
│   └── README.md             # Examples documentation
└── .github/
    └── workflows/
        └── ci.yml            # GitHub Actions CI/CD
```

## Development Guidelines

### Code Style
- Follow consistent code formatting (use provided linter/formatter configs)
- Write clear, descriptive variable and function names
- Add comments for complex logic
- Keep functions focused and modular

### Testing
- Write tests for new features
- Ensure all tests pass before committing
- Aim for good test coverage on critical paths

### Git Workflow
- Use descriptive commit messages
- Follow conventional commit format when applicable
- Keep commits atomic and focused
- Branch naming: use `feature/`, `fix/`, or `claude/` prefixes

## Common Tasks

### Running Tests
```bash
npm test
```

### Building
```bash
npm run build
```

### Linting
```bash
npm run lint
```

## Architecture Notes

### Templating Engine Flow

1. **Lexer** (`lexer.ts`): Converts template strings into tokens
   - Handles custom delimiters (`{{` `}}` by default)
   - Separates text, variables, and control flow tags
   - Expression tokenization for complex expressions

2. **Parser** (`parser.ts`): Builds Abstract Syntax Tree (AST)
   - Converts tokens into structured AST nodes
   - Supports: variables, conditionals, loops, blocks, includes
   - Expression parser handles operators, member access, function calls

3. **Compiler** (`compiler.ts`): Transforms AST to executable code
   - Generates optimized render functions
   - Applies filters during compilation
   - Handles template inheritance and composition

4. **Runtime** (`runtime.ts`): Evaluates expressions
   - Safe expression evaluation without eval()
   - Binary operators: +, -, *, /, %, ==, !=, <, >, <=, >=, and, or
   - Unary operators: -, !, not
   - Member access and function calls

### Key Components

**Template Class** (`template.ts`)
- Main synchronous API
- Template compilation and rendering
- Filter and helper management
- File-based template loading
- LRU caching integration

**AsyncTemplate Class** (`async-template.ts`)
- Async file loading with fs/promises
- Batch template preloading
- Same rendering API as Template

**Filter System** (`filters.ts`)
- 30+ built-in filters
- Categories: string, array, number, utility, date
- Custom filter registration
- Filter chaining support

**Cache** (`cache.ts`)
- LRU (Least Recently Used) eviction
- Configurable max size
- Access order tracking
- Cache clearing

### Template Syntax Features

**Variables:**
```html
{{ variable }}
{{ object.property }}
{{ array.0 }}
```

**Filters:**
```html
{{ value | upper }}
{{ price | fixed(2) }}
{{ items | length }}
{{ text | truncate(100) | capitalize }}
```

**Conditionals:**
```html
{% if condition %}
  ...
{% elif other %}
  ...
{% else %}
  ...
{% endif %}
```

**Loops:**
```html
{% for item in items %}
  {{ loop.index }}: {{ item }}
{% endfor %}
```

**Inheritance:**
```html
{% extends "base.html" %}
{% block content %}...{% endblock %}
```

**Includes:**
```html
{% include "header.html" %}
```

## Dependencies

### Production Dependencies
- **he** (^1.2.0): HTML entity encoding/decoding for XSS protection

### Development Dependencies
- **TypeScript** (^5.2.0): Type safety and modern JavaScript features
- **Jest** (^29.7.0): Testing framework with great TypeScript support
- **ts-jest** (^29.1.0): Jest TypeScript preprocessor
- **ESLint** (^8.50.0): Code quality and consistency
- **@typescript-eslint/***: TypeScript-specific linting rules
- **Prettier** (^3.0.0): Code formatting
- **@types/node** (^20.0.0): Node.js type definitions
- **@types/jest** (^29.5.0): Jest type definitions

### Why Minimal Dependencies?
- Smaller bundle size
- Fewer security vulnerabilities
- Faster installation
- Less maintenance overhead
- Better reliability

## Configuration

### Template Options

```typescript
interface TemplateOptions {
  delimiters?: { start: string; end: string };  // Default: {{ }}
  autoEscape?: boolean;                         // Default: true
  strictMode?: boolean;                         // Default: false
  cache?: boolean;                              // Default: true
  filters?: Record<string, FilterFunction>;     // Custom filters
  helpers?: Record<string, HelperFunction>;     // Custom helpers
  plugins?: Plugin[];                           // Plugins to install
}
```

### NPM Scripts

```bash
npm run build          # Compile TypeScript to dist/
npm run build:watch    # Watch mode compilation
npm test               # Run all tests
npm run test:watch     # Watch mode testing
npm run test:coverage  # Generate coverage report
npm run lint           # Run ESLint
npm run lint:fix       # Auto-fix linting issues
npm run format         # Format code with Prettier
npm run benchmark      # Run performance benchmarks
```

### CLI Usage

```bash
v3t -t template.html -d data.json -o output.html
v3t --help
v3t --version
```

## Security Considerations

### Built-in Security Features

1. **Auto-escaping by default**
   - All variables are HTML-escaped unless marked safe
   - Prevents XSS attacks automatically
   - Use `{{ value | safe }}` only for trusted content

2. **No eval() or Function()**
   - Templates compiled without arbitrary code execution
   - Expression evaluation uses AST interpretation
   - Cannot execute user-provided JavaScript

3. **SafeString class**
   - Explicit marking of trusted HTML content
   - Type-safe approach to bypassing escaping
   - Clear audit trail for security review

4. **Strict Mode**
   - Throws errors on undefined variables
   - Catches typos and missing data early
   - Recommended for development environment

5. **Sandboxed Filters**
   - Filters cannot access global scope
   - No access to require() or process
   - Pure function transformations only

### Security Best Practices

- Always validate user input before passing to templates
- Use strict mode in development
- Review all usage of `safe` filter
- Keep dependencies updated (npm audit)
- Don't disable auto-escaping unless necessary
- Sanitize data at input, escape at output

## Performance

### Benchmarks (on modern hardware)

- **Simple variables**: ~100,000 ops/sec
- **With caching**: ~500,000+ ops/sec
- **Complex templates**: ~50,000 ops/sec
- **Filters**: ~100,000 ops/sec
- **Loops (100 items)**: ~10,000 ops/sec

### Optimization Strategies

1. **LRU Caching**
   - Compiled templates cached by default
   - Configurable cache size (default: 100)
   - Least recently used eviction policy

2. **Compile Once, Render Many**
   ```javascript
   const compiled = template.compile(tmpl);
   const result1 = compiled.render(data1);
   const result2 = compiled.render(data2);
   ```

3. **Async Template Preloading**
   ```javascript
   await asyncTemplate.preload(['layout.html', 'header.html']);
   ```

4. **Filter Optimization**
   - Apply filters outside loops when possible
   - Chain filters efficiently
   - Use built-in filters (they're optimized)

### Running Benchmarks

```bash
npm run build
npm run benchmark
```

## Known Issues & Limitations

### Current Limitations (v1.0.0)

1. **No async filter support**
   - Filters must be synchronous
   - Planned for v1.1.0

2. **No macro support**
   - Cannot define reusable template fragments
   - Planned for v1.2.0

3. **No streaming support**
   - Templates rendered in full before returning
   - Planned for v1.3.0

4. **Limited date formatting**
   - Basic ISO/locale formatting only
   - Enhanced date filters planned for v1.1.0

5. **No browser build yet**
   - Node.js only currently
   - Browser build (UMD/ESM) planned for v1.1.0

### Future Enhancements

See CHANGELOG.md for roadmap:
- v1.1.0: Async filters, browser build, streaming
- v1.2.0: Macros, debugging tools, more filters
- v1.3.0: Template linting, IDE support, hot reload

## Resources

### Documentation
- **README.md**: User guide with examples and comparisons
- **docs/API.md**: Complete API reference
- **docs/MIGRATION.md**: Migration from Handlebars, EJS, Mustache, Pug, Liquid
- **examples/**: Real-world template examples
- **CONTRIBUTING.md**: Development guidelines

### Inspiration
- **Jinja2** (Python): Template inheritance and filter syntax
- **Liquid** (Ruby): Clean, safe templating for untrusted users
- **Handlebars** (JS): Helper system and partials
- **Mustache** (Multi): Logic-less philosophy
- **EJS** (JS): Simple embedded templates

### Testing
- **Jest**: Modern testing framework
- **Coverage target**: 80%+ (currently achieved)
- **Test files**: src/__tests__/*.test.ts

### Related Projects
- Template engines: Handlebars, EJS, Pug, Nunjucks, Mustache
- Security: DOMPurify, js-xss, validator.js
- Rendering: React, Vue, Angular

## Notes for Claude

- When making changes, always run tests if available
- Follow the existing code style and patterns
- Ask for clarification on ambiguous requirements
- Suggest improvements when you notice code smells or potential issues
- Consider security implications, especially for template evaluation
- Be cautious with external input and user-provided templates
