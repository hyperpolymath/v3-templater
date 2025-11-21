# v3-templater

## Project Overview

v3-templater is a templating system project. This document provides context for Claude Code to effectively assist with development.

## Project Structure

```
v3-templater/
├── CLAUDE.md          # This file - project context for Claude
├── README.md          # User-facing documentation
├── package.json       # Project dependencies and scripts
├── src/               # Source code
├── tests/             # Test files
└── docs/              # Additional documentation
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

### Templating Engine
- Document the template syntax and supported features
- Explain variable interpolation mechanisms
- Describe any template inheritance or composition patterns

### Key Components
- Add information about main modules and their responsibilities
- Document important interfaces and data structures
- Note any significant design patterns in use

## Dependencies

- List and explain key dependencies
- Note any version-specific requirements
- Document reasons for major dependency choices

## Configuration

- Environment variables and their purposes
- Configuration file formats and locations
- Default values and how to override them

## Security Considerations

- Input validation and sanitization
- Template injection prevention
- Safe evaluation of user-provided templates
- Dependency vulnerability monitoring

## Performance

- Template caching strategies
- Optimization techniques for large templates
- Benchmarking and profiling approaches

## Known Issues & Limitations

- Document any current limitations
- Track known bugs or technical debt
- Note future improvements planned

## Resources

- Link to relevant documentation
- Related projects or inspiration sources
- Useful references for contributors

## Notes for Claude

- When making changes, always run tests if available
- Follow the existing code style and patterns
- Ask for clarification on ambiguous requirements
- Suggest improvements when you notice code smells or potential issues
- Consider security implications, especially for template evaluation
- Be cautious with external input and user-provided templates
