/**
 * v3-templater - JavaScript/Deno interop layer
 * This file provides a JavaScript API over the ReScript compiled code
 */

// Import ReScript compiled modules (will be .bs.js files)
// Note: These imports will work after ReScript compilation
import * as TypesModule from './Types.bs.js';
import * as LexerModule from './Lexer.bs.js';
import * as RuntimeModule from './Runtime.bs.js';
import * as CacheModule from './Cache.bs.js';
import * as EscapeModule from './utils/Escape.bs.js';

/**
 * Template Engine Class
 * Main API for template compilation and rendering
 */
export class Template {
  constructor(options = {}) {
    this.options = {
      autoEscape: options.autoEscape ?? true,
      strictMode: options.strictMode ?? false,
      cache: options.cache ?? true,
      delimiters: options.delimiters ?? { start: '{{', end: '}}' },
      filters: options.filters ?? {},
      helpers: options.helpers ?? {},
    };

    // Initialize cache if enabled
    this.cacheState = this.options.cache ? CacheModule.make(100) : null;

    // Store custom filters and helpers
    this.customFilters = { ...this.options.filters };
    this.customHelpers = { ...this.options.helpers };
  }

  /**
   * Compile a template string
   */
  compile(templateString) {
    // Check cache first
    if (this.cacheState) {
      const cached = CacheModule.get(this.cacheState, templateString);
      if (cached) {
        return {
          render: (context) => this.render(templateString, context),
        };
      }
    }

    // Create lexer with configured delimiters
    const delimiterConfig = {
      start: this.options.delimiters.start,
      end_: this.options.delimiters.end,
    };
    const lexer = LexerModule.make(templateString, delimiterConfig);

    // Tokenize the template
    const tokens = LexerModule.tokenize(lexer);

    // For now, return a compiled template object
    // In a full implementation, we'd parse and compile the tokens
    const compiled = {
      render: (context) => this.render(templateString, context),
      source: templateString,
      tokens: tokens,
    };

    // Cache if enabled
    if (this.cacheState) {
      CacheModule.set(this.cacheState, templateString, compiled);
    }

    return compiled;
  }

  /**
   * Render a template string with context
   */
  render(templateString, context = {}) {
    // Simple rendering implementation
    // This is a minimal version - full implementation would use parser & compiler

    let output = templateString;

    // Handle variable substitution {{ variable }}
    const varRegex = new RegExp(
      `${this.escapeRegex(this.options.delimiters.start)}\\s*([^}]+?)\\s*${this.escapeRegex(this.options.delimiters.end)}`,
      'g'
    );

    output = output.replace(varRegex, (match, varName) => {
      // Get value from context
      const value = this.getContextValue(varName.trim(), context);

      // Convert to string
      const strValue = this.valueToString(value);

      // Escape if needed
      if (this.options.autoEscape) {
        return EscapeModule.escapeHtml(strValue);
      }
      return strValue;
    });

    return output;
  }

  /**
   * Render a template file
   */
  async renderFile(filePath, context = {}) {
    const content = await Deno.readTextFile(filePath);
    return this.render(content, context);
  }

  /**
   * Add a custom filter
   */
  addFilter(name, fn) {
    this.customFilters[name] = fn;
  }

  /**
   * Add a custom helper
   */
  addHelper(name, fn) {
    this.customHelpers[name] = fn;
  }

  /**
   * Clear template cache
   */
  clearCache() {
    if (this.cacheState) {
      CacheModule.clear(this.cacheState);
    }
  }

  // Helper methods

  getContextValue(path, context) {
    const parts = path.split('.');
    let value = context;

    for (const part of parts) {
      if (value == null) return null;
      value = value[part];
    }

    return value ?? null;
  }

  valueToString(value) {
    if (value == null) return '';
    if (typeof value === 'string') return value;
    if (typeof value === 'number') return String(value);
    if (typeof value === 'boolean') return String(value);
    if (typeof value === 'object') return JSON.stringify(value);
    return String(value);
  }

  escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
}

/**
 * Async Template Engine
 * Same as Template but with async file operations
 */
export class AsyncTemplate extends Template {
  async renderFile(filePath, context = {}) {
    const content = await Deno.readTextFile(filePath);
    return this.render(content, context);
  }

  async preload(filePaths) {
    const promises = filePaths.map(async (path) => {
      const content = await Deno.readTextFile(path);
      this.compile(content);
    });
    await Promise.all(promises);
  }
}

// Export utility functions
export { EscapeModule as Escape };
export { RuntimeModule as Runtime };
export { LexerModule as Lexer };
export { CacheModule as Cache };

// Default export
export default {
  Template,
  AsyncTemplate,
  Escape: EscapeModule,
  Runtime: RuntimeModule,
  Lexer: LexerModule,
  Cache: CacheModule,
};
