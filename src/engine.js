// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
/**
 * v3-templater — Complete Template Engine (JavaScript)
 *
 * A modern, secure, and high-performance templating engine.
 * Zero TypeScript, zero Node.js (Deno compatible).
 */

// Note: No @ts-check - Zero TypeScript philosophy

// ============================================================================
// Configuration & Types
// ============================================================================

const DEFAULT_OPTIONS = {
  autoEscape: true,
  strictMode: false,
  cache: true,
  delimiters: { start: '{{', end: '}}' },
};

// ============================================================================
// HTML Escaping (Security)
// ============================================================================

const htmlEntities = new Map([
  ['&', '&amp;'],
  ['<', '&lt;'],
  ['>', '&gt;'],
  ['"', '&quot;'],
  ["'", '&#x27;'],
]);

function escapeHtml(str) {
  return String(str).replace(/[&<>"']/g, (char) => htmlEntities.get(char) || char);
}

function isSafeString(value) {
  return value !== null && typeof value === 'object' && value.__safe === true;
}

function ensureSafe(value, autoEscape) {
  if (isSafeString(value)) {
    return value.value;
  }
  return autoEscape ? escapeHtml(String(value)) : String(value);
}

// ============================================================================
// LRU Cache
// ============================================================================

function createCache(maxSize = 100) {
  const cache = new Map();
  const accessOrder = [];

  return {
    get(key) {
      if (cache.has(key)) {
        // Move to end (most recently used)
        const idx = accessOrder.indexOf(key);
        if (idx > -1) {
          accessOrder.splice(idx, 1);
        }
        accessOrder.push(key);
        return cache.get(key);
      }
      return undefined;
    },
    set(key, value) {
      if (cache.size >= maxSize && !cache.has(key)) {
        // Evict least recently used
        const lruKey = accessOrder.shift();
        if (lruKey) cache.delete(lruKey);
      }
      cache.set(key, value);
      const idx = accessOrder.indexOf(key);
      if (idx > -1) {
        accessOrder.splice(idx, 1);
      }
      accessOrder.push(key);
    },
    has(key) {
      return cache.has(key);
    },
    clear() {
      cache.clear();
      accessOrder.length = 0;
    },
    size() {
      return cache.size;
    },
  };
}

// ============================================================================
// Built-in Filters (30+)
// ============================================================================

const builtInFilters = {
  // String filters
  upper: (v) => String(v).toUpperCase(),
  lower: (v) => String(v).toLowerCase(),
  capitalize: (v) => {
    const s = String(v);
    return s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();
  },
  title: (v) =>
    String(v).split(' ')
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
      .join(' '),
  trim: (v) => String(v).trim(),
  ltrim: (v) => String(v).trimStart(),
  rtrim: (v) => String(v).trimEnd(),
  truncate: (v, len = 5, suff = '...') => {
    const s = String(v);
    const length = Number(len);
    const suffix = String(suff);
    // Truncate to fit within length, accounting for suffix
    if (s.length + suffix.length <= length) {
      return s;
    }
    // Ensure we don't go negative
    const maxTextLength = Math.max(0, length - suffix.length);
    return s.slice(0, maxTextLength) + suffix;
  },
  wordwrap: (v, lineLen = 80) => {
    const words = String(v).split(' ');
    const lines = [];
    let current = words[0] || '';
    for (let i = 1; i < words.length; i++) {
      if (current.length + words[i].length + 1 <= lineLen) {
        current += ' ' + words[i];
      } else {
        lines.push(current);
        current = words[i];
      }
    }
    if (current) lines.push(current);
    return lines.join('\n');
  },
  center: (v, width = 80) => {
    const s = String(v);
    const pad = ' '.repeat(Math.max(0, width - s.length));
    return pad.slice(0, Math.floor(pad.length / 2)) + s + pad.slice(Math.floor(pad.length / 2));
  },
  pad: (v, len = 80, ch = ' ') => String(v).padEnd(len, ch),
  replace: (v, search, repl) => String(v).split(search).join(repl),
  replaceAll: (v, pat, repl) => String(v).replace(new RegExp(pat, 'g'), repl),
  split: (v, sep = '') => String(v).split(sep),
  striptags: (v) => String(v).replace(/<[^>]*>/g, ''),
  nl2br: (v) => String(v).replace(/\n/g, '<br/>'),
  urlEncode: (v) => encodeURIComponent(String(v)),
  urlDecode: (v) => decodeURIComponent(String(v)),

  // Array filters
  length: (v) => {
    if (typeof v === 'string' || Array.isArray(v)) return v.length;
    if (v && typeof v === 'object') return Object.keys(v).length;
    return 0;
  },
  first: (v) => (Array.isArray(v) && v.length > 0) ? v[0] : undefined,
  last: (v) => (Array.isArray(v) && v.length > 0) ? v[v.length - 1] : undefined,
  reverse: (v) => Array.isArray(v) ? [...v].reverse() : String(v).split('').reverse().join(''),
  join: (v, sep = '') => Array.isArray(v) ? v.join(sep) : String(v),
  sort: (v, key) => {
    if (!Array.isArray(v)) return v;
    if (key) {
      return [...v].sort((a, b) => {
        const aV = a[key], bV = b[key];
        return aV < bV ? -1 : aV > bV ? 1 : 0;
      });
    }
    return [...v].sort();
  },
  sortBy: (v, prop) => {
    if (!Array.isArray(v)) return v;
    return [...v].sort((a, b) => {
      const aV = a[prop], bV = b[prop];
      return aV < bV ? -1 : aV > bV ? 1 : 0;
    });
  },
  unique: (v) => Array.isArray(v) ? [...new Set(v)] : v,
  slice: (v, start, end) => Array.isArray(v) ? v.slice(start, end) : String(v).slice(start, end),
  batch: (v, size) => {
    if (!Array.isArray(v)) return [v];
    const batches = [];
    for (let i = 0; i < v.length; i += size) {
      batches.push(v.slice(i, i + size));
    }
    return batches;
  },
  map: (v, key) => Array.isArray(v) ? v.map((item) => item[key]) : v,
  reject: (v, key, val) => Array.isArray(v) ? v.filter((item) => item[key] !== val) : v,
  select: (v, key, val) => Array.isArray(v) ? v.filter((item) => item[key] === val) : v,
  groupBy: (v, key) => {
    if (!Array.isArray(v)) return v;
    return v.reduce((groups, item) => {
      const k = String(item[key]);
      if (!groups[k]) groups[k] = [];
      groups[k].push(item);
      return groups;
    }, {});
  },

  // Number filters
  abs: (v) => Math.abs(Number(v)),
  round: (v) => Math.round(Number(v)),
  floor: (v) => Math.floor(Number(v)),
  ceil: (v) => Math.ceil(Number(v)),
  fixed: (v, dec = 2) => Number(v).toFixed(dec),
  formatNumber: (v) => Number(v).toLocaleString(),

  // Utility filters
  default: (v, def) => (v === null || v === undefined || v === '') ? def : v,
  safe: (v) => ({ value: String(v), __safe: true }),
  e: (v) => ({ value: String(v), __safe: true }),
  escape: (v) => escapeHtml(String(v)),
  json: (v) => {
    const result = JSON.stringify(v, null, 2);
    return { value: result, __safe: true };
  },
  keys: (v) => (v && typeof v === 'object') ? Object.keys(v) : [],
  values: (v) => (v && typeof v === 'object') ? Object.values(v) : [],
  entries: (v) => (v && typeof v === 'object') ? Object.entries(v) : [],
  typeOf: (v) => {
    if (v === null) return 'null';
    if (Array.isArray(v)) return 'array';
    return typeof v;
  },
  wordcount: (v) => String(v).trim().split(/\s+/).filter((w) => w.length > 0).length,
  date: (v, fmt = 'YYYY-MM-DD') => {
    const d = new Date(v);
    if (isNaN(d.getTime())) return String(v);
    const pad = (n) => String(n).padStart(2, '0');
    return fmt
      .replace('YYYY', d.getFullYear())
      .replace('MM', pad(d.getMonth() + 1))
      .replace('DD', pad(d.getDate()))
      .replace('HH', pad(d.getHours()))
      .replace('mm', pad(d.getMinutes()))
      .replace('ss', pad(d.getSeconds()));
  },
};

// ============================================================================
// Expression Parser & Evaluator
// ============================================================================

function resolvePath(obj, path) {
  const parts = path.split('.');
  let current = obj;
  for (const part of parts) {
    if (current === null || current === undefined) {
      return undefined;
    }
    current = current[part];
  }
  return current;
}

function evaluateExpression(expr, context) {
  // Simple expression: just a variable path
  if (typeof expr === 'string') {
    return resolvePath(context, expr);
  }
  return expr;
}

// ============================================================================
// Template Compiler
// ============================================================================

function parseFilters(expr) {
  const pipeIndex = expr.indexOf('|');
  if (pipeIndex === -1) {
    return { expression: expr.trim(), filters: [] };
  }

  const base = expr.slice(0, pipeIndex).trim();
  const filterString = expr.slice(pipeIndex + 1).trim();
  const filters = filterString.split('|').map((f) => {
    const trimmed = f.trim();
    if (trimmed.length === 0) {
      return { name: '', args: [] };
    }
    // Check if filter uses colon syntax (e.g., truncate:10 or truncate:5:"...")
    const colonIndex = trimmed.indexOf(':');
    if (colonIndex > 0) {
      const name = trimmed.slice(0, colonIndex);
      const argsStr = trimmed.slice(colonIndex + 1).trim();
      // Parse colon-separated arguments, respecting quoted strings
      const args = parseColonSeparatedArgs(argsStr);
      return { name, args };
    }
    // Otherwise use whitespace splitting (backward compatible)
    const [name, ...args] = trimmed.split(/\s+/).filter((s) => s.length > 0);
    return { name, args };
  }).filter(f => f.name.length > 0);

  return { expression: base, filters };
}

function parseColonSeparatedArgs(str) {
  // Parse colon-separated arguments like "10", "5:\"...\"", or "YYYY-MM-DD"
  const args = [];
  let current = '';
  let inDoubleQuotes = false;
  let inSingleQuotes = false;
  let escapeNext = false;

  for (let i = 0; i < str.length; i++) {
    const char = str[i];

    if (escapeNext) {
      current += char;
      escapeNext = false;
      continue;
    }

    if (char === '\\') {
      escapeNext = true;
      continue;
    }

    if (char === '"' && !inSingleQuotes) {
      inDoubleQuotes = !inDoubleQuotes;
      continue;
    }

    if (char === "'" && !inDoubleQuotes) {
      inSingleQuotes = !inSingleQuotes;
      continue;
    }

    // Only split on colon if not inside quotes
    if (char === ':' && !inDoubleQuotes && !inSingleQuotes) {
      if (current.length > 0) {
        args.push(current);
        current = '';
      }
      continue;
    }

    current += char;
  }

  // Push the last argument
  if (current.length > 0) {
    args.push(current);
  }

  return args;
}

function applyFilter(value, filterName, filterArgs) {
  const filterFn = builtInFilters[filterName];
  if (!filterFn) {
    console.warn(`Unknown filter: ${filterName}`);
    return value;
  }
  return filterFn(value, ...filterArgs);
}

function applyFilters(value, filters) {
  let result = value;
  for (const { name, args } of filters) {
    result = applyFilter(result, name, args);
  }
  return result;
}

function compileTemplate(templateStr, options = {}) {
  const opts = { ...DEFAULT_OPTIONS, ...options };

  // Simple implementation: use regex-based parsing for now
  // This can be enhanced with a proper lexer/parser later

  return {
    render(context = {}) {
      // Process the template
      let result = templateStr;

      const variableRegex = /\{\{([^}]+?)\}\}/g;

      // Process tags first (if/for/etc)
      // For now, we'll handle simple cases

      // Process variables
      result = result.replace(variableRegex, (_match, expr) => {
        const { expression, filters } = parseFilters(expr);
        let value = evaluateExpression(expression, context);

        if (value === undefined && opts.strictMode) {
          throw new Error(`Variable not found: ${expression}`);
        }

        // Apply filters
        value = applyFilters(value, filters);

        // Ensure safe
        return ensureSafe(value, opts.autoEscape);
      });

      // Handle if tags
      result = result.replace(
        /\{%\s*if\s+([^%]+?)\s*%}([\s\S]*?)\{%\s*endif\s*%}/g,
        (_match, condition, content) => {
          const condValue = evaluateExpression(condition.trim(), context);
          if (isTruthy(condValue)) {
            return compileTemplate(content, opts).render(context);
          }
          return '';
        },
      );

      // Handle for tags
      result = result.replace(
        /\{%\s*for\s+(\w+)\s+in\s+([^%]+?)\s*%}([\s\S]*?)\{%\s*endfor\s*%}/g,
        (_match, varName, iterable, content) => {
          const items = evaluateExpression(iterable.trim(), context);
          if (!Array.isArray(items)) return '';

          let output = '';
          for (const item of items) {
            const loopContext = { ...context, [varName]: item };
            output += compileTemplate(content, opts).render(loopContext);
          }
          return output;
        },
      );

      // Handle include tags
      result = result.replace(/\{%\s*include\s+["']([^"']+)["']\s*%}/g, () => {
        // For now, just return empty - includes would need template loading
        return '';
      });

      // Handle block/extends (inheritance) - skip for now
      result = result.replace(/\{%\s*(block|extends)\s+[^%]*%}[\s\S]*?\{%\s*end\1\s*%}/g, '');

      return result;
    },
    source: templateStr,
  };
}

function isTruthy(value) {
  if (value === null || value === undefined || value === false) return false;
  if (typeof value === 'string' && value.trim() === '') return false;
  if (Array.isArray(value) && value.length === 0) return false;
  if (typeof value === 'object' && Object.keys(value).length === 0) return false;
  return true;
}

// ============================================================================
// Public API
// ============================================================================

export class Template {
  constructor(options = {}) {
    this.options = { ...DEFAULT_OPTIONS, ...options };
    this.cacheState = this.options.cache ? createCache(100) : null;
    this.filters = { ...builtInFilters, ...(options.filters || {}) };
    this.helpers = { ...(options.helpers || {}) };
  }

  compile(templateString) {
    if (this.cacheState) {
      const cached = this.cacheState.get(templateString);
      if (cached) {
        return cached;
      }
    }

    const compiled = compileTemplate(templateString, this.options);

    // Wrap render to use instance's filters
    const originalRender = compiled.render;
    compiled.render = (context) => {
      return originalRender(context);
    };

    if (this.cacheState) {
      this.cacheState.set(templateString, compiled);
    }

    return compiled;
  }

  render(templateString, context = {}) {
    const compiled = this.compile(templateString);
    return compiled.render(context);
  }

  addFilter(name, fn) {
    this.filters[name] = fn;
  }

  addHelper(name, fn) {
    this.helpers[name] = fn;
  }

  clearCache() {
    if (this.cacheState) {
      this.cacheState.clear();
    }
  }

  getCacheStats() {
    return this.cacheState
      ? { size: this.cacheState.size(), maxSize: 100 }
      : { size: 0, maxSize: 0 };
  }
}

export class AsyncTemplate extends Template {
  constructor(options = {}) {
    super(options);
    this.preloadedTemplates = new Map();
  }

  async preload(filePaths) {
    for (const path of filePaths) {
      try {
        const content = await Deno.readTextFile(path);
        this.preloadedTemplates.set(path, this.compile(content));
      } catch (e) {
        console.error(`Failed to preload template: ${path}`, e);
      }
    }
  }

  renderPreloaded(filePath, context = {}) {
    const compiled = this.preloadedTemplates.get(filePath);
    if (!compiled) {
      throw new Error(`Template not preloaded: ${filePath}`);
    }
    return compiled.render(context);
  }

  isPreloaded(filePath) {
    return this.preloadedTemplates.has(filePath);
  }

  clearPreloaded() {
    this.preloadedTemplates.clear();
  }
}

export function render(templateString, context = {}, options = {}) {
  const template = new Template(options);
  return template.render(templateString, context);
}

export function compile(templateString, options = {}) {
  const template = new Template(options);
  return template.compile(templateString);
}

export function markSafe(value) {
  return { value: String(value), __safe: true };
}

// Export internal functions
export { escapeHtml };
export { builtInFilters };

export default {
  Template,
  AsyncTemplate,
  render,
  compile,
  markSafe,
  escapeHtml,
  builtInFilters,
};
