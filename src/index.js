/**
 * v3-templater - JavaScript/Deno interop layer
 * This file provides a JavaScript API over the ReScript compiled code
 */

// Import ReScript compiled modules (will be .bs.js files after compilation)
// Note: These imports will work after ReScript compilation
import * as TypesModule from './Types.bs.js';
import * as LexerModule from './Lexer.bs.js';
import * as ParserModule from './Parser.bs.js';
import * as CompilerModule from './Compiler.bs.js';
import * as RuntimeModule from './Runtime.bs.js';
import * as FiltersModule from './Filters.bs.js';
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

    // Merge custom filters with built-in filters
    this.filters = FiltersModule.mergeFilters(this.options.filters);
    this.helpers = { ...this.options.helpers };

    // Compiler options
    this.compilerOptions = {
      autoEscape: this.options.autoEscape,
      strictMode: this.options.strictMode,
      filters: this.filters,
      helpers: this.helpers,
    };
  }

  /**
   * Compile a template string into a reusable render function
   * @param {string} templateString - The template to compile
   * @returns {{ render: (context: object) => string, source: string }}
   */
  compile(templateString) {
    // Check cache first
    if (this.cacheState) {
      const cached = CacheModule.get(this.cacheState, templateString);
      if (cached) {
        return cached;
      }
    }

    // Convert delimiters for ReScript
    const delimiterConfig = this.options.delimiters ? {
      start: this.options.delimiters.start,
      end_: this.options.delimiters.end,
    } : undefined;

    // Compile template using ReScript compiler
    const compiled = CompilerModule.compile(
      templateString,
      this.compilerOptions,
      delimiterConfig
    );

    // Wrap the render function for easier use
    const result = {
      render: (context = {}) => {
        return compiled.render(context);
      },
      source: templateString,
    };

    // Cache if enabled
    if (this.cacheState) {
      CacheModule.set(this.cacheState, templateString, result);
    }

    return result;
  }

  /**
   * Render a template string with context directly
   * @param {string} templateString - The template to render
   * @param {object} context - Data to pass to the template
   * @returns {string}
   */
  render(templateString, context = {}) {
    const compiled = this.compile(templateString);
    return compiled.render(context);
  }

  /**
   * Render a template file (sync version - Node.js only)
   * @param {string} filePath - Path to the template file
   * @param {object} context - Data to pass to the template
   * @returns {string}
   */
  renderFileSync(filePath, context = {}) {
    // For Node.js environments
    if (typeof require !== 'undefined') {
      const fs = require('fs');
      const content = fs.readFileSync(filePath, 'utf8');
      return this.render(content, context);
    }
    throw new Error('renderFileSync requires Node.js. Use renderFile for async file reading.');
  }

  /**
   * Render a template file (async version)
   * @param {string} filePath - Path to the template file
   * @param {object} context - Data to pass to the template
   * @returns {Promise<string>}
   */
  async renderFile(filePath, context = {}) {
    // Deno environment
    if (typeof Deno !== 'undefined') {
      const content = await Deno.readTextFile(filePath);
      return this.render(content, context);
    }
    // Node.js environment
    if (typeof require !== 'undefined') {
      const fs = require('fs').promises;
      const content = await fs.readFile(filePath, 'utf8');
      return this.render(content, context);
    }
    throw new Error('renderFile requires Deno or Node.js runtime.');
  }

  /**
   * Add a custom filter
   * @param {string} name - Filter name
   * @param {Function} fn - Filter function (value, ...args) => result
   */
  addFilter(name, fn) {
    this.filters[name] = fn;
    this.compilerOptions.filters = this.filters;
  }

  /**
   * Add a custom helper function
   * @param {string} name - Helper name
   * @param {Function} fn - Helper function (...args) => result
   */
  addHelper(name, fn) {
    this.helpers[name] = fn;
    this.compilerOptions.helpers = this.helpers;
  }

  /**
   * Clear template cache
   */
  clearCache() {
    if (this.cacheState) {
      CacheModule.clear(this.cacheState);
    }
  }

  /**
   * Get cache statistics
   * @returns {{ size: number, maxSize: number }}
   */
  getCacheStats() {
    if (this.cacheState) {
      return {
        size: CacheModule.size(this.cacheState),
        maxSize: 100,
      };
    }
    return { size: 0, maxSize: 0 };
  }
}

/**
 * Async Template Engine
 * Optimized for async file operations and batch preloading
 */
export class AsyncTemplate extends Template {
  constructor(options = {}) {
    super(options);
    this.preloadedTemplates = new Map();
  }

  /**
   * Preload multiple templates for faster rendering
   * @param {string[]} filePaths - Array of file paths to preload
   * @returns {Promise<void>}
   */
  async preload(filePaths) {
    const promises = filePaths.map(async (path) => {
      // Deno environment
      if (typeof Deno !== 'undefined') {
        const content = await Deno.readTextFile(path);
        this.preloadedTemplates.set(path, this.compile(content));
        return;
      }
      // Node.js environment
      if (typeof require !== 'undefined') {
        const fs = require('fs').promises;
        const content = await fs.readFile(path, 'utf8');
        this.preloadedTemplates.set(path, this.compile(content));
        return;
      }
    });
    await Promise.all(promises);
  }

  /**
   * Render a preloaded template
   * @param {string} filePath - Path used during preload
   * @param {object} context - Data to pass to the template
   * @returns {string}
   */
  renderPreloaded(filePath, context = {}) {
    const compiled = this.preloadedTemplates.get(filePath);
    if (!compiled) {
      throw new Error(`Template not preloaded: ${filePath}`);
    }
    return compiled.render(context);
  }

  /**
   * Check if a template is preloaded
   * @param {string} filePath - Path to check
   * @returns {boolean}
   */
  isPreloaded(filePath) {
    return this.preloadedTemplates.has(filePath);
  }

  /**
   * Clear preloaded templates
   */
  clearPreloaded() {
    this.preloadedTemplates.clear();
  }
}

/**
 * SafeString class for marking content as safe (no escaping)
 */
export class SafeString {
  constructor(value) {
    this.value = String(value);
    this.__safe = true;
  }

  toString() {
    return this.value;
  }

  valueOf() {
    return this.value;
  }
}

/**
 * Mark a string as safe (no HTML escaping)
 * @param {string} value - Value to mark as safe
 * @returns {SafeString}
 */
export function markSafe(value) {
  return new SafeString(value);
}

/**
 * Escape HTML entities in a string
 * @param {string} str - String to escape
 * @returns {string}
 */
export function escapeHtml(str) {
  return EscapeModule.escapeHtml(String(str));
}

/**
 * Create a template with default options
 * Convenience function for quick usage
 * @param {string} templateString - Template to compile
 * @param {object} context - Data for rendering
 * @returns {string}
 */
export function render(templateString, context = {}) {
  const template = new Template();
  return template.render(templateString, context);
}

/**
 * Compile a template with default options
 * @param {string} templateString - Template to compile
 * @returns {{ render: (context: object) => string }}
 */
export function compile(templateString) {
  const template = new Template();
  return template.compile(templateString);
}

// Export utility modules for advanced usage
export const Escape = EscapeModule;
export const Runtime = RuntimeModule;
export const Lexer = LexerModule;
export const Parser = ParserModule;
export const Compiler = CompilerModule;
export const Filters = FiltersModule;
export const Cache = CacheModule;
export const Types = TypesModule;

// Export built-in filter names for reference
export const builtInFilters = [
  // String filters
  'upper', 'lower', 'capitalize', 'title', 'trim', 'ltrim', 'rtrim',
  'truncate', 'wordwrap', 'center', 'pad', 'replace', 'replaceAll',
  'split', 'striptags', 'nl2br', 'urlEncode', 'urlDecode',
  // Array filters
  'length', 'first', 'last', 'reverse', 'join', 'sort', 'sortBy',
  'unique', 'slice', 'batch', 'map', 'reject', 'select', 'groupBy',
  // Number filters
  'abs', 'round', 'floor', 'ceil', 'fixed', 'formatNumber',
  // Utility filters
  'default', 'safe', 'escape', 'e', 'json', 'keys', 'values',
  'entries', 'typeOf', 'wordcount',
  // Date filters
  'date',
];

// Default export
export default {
  Template,
  AsyncTemplate,
  SafeString,
  markSafe,
  escapeHtml,
  render,
  compile,
  builtInFilters,
  // Internal modules
  Escape: EscapeModule,
  Runtime: RuntimeModule,
  Lexer: LexerModule,
  Parser: ParserModule,
  Compiler: CompilerModule,
  Filters: FiltersModule,
  Cache: CacheModule,
  Types: TypesModule,
};
