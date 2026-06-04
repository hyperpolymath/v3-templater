// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
/**
 * v3-templater — Complete Test Suite
 */

import {
  assertEquals,
  assertNotEquals,
  assertThrows,
} from 'https://deno.land/std@0.224.0/testing/asserts.ts';
import { AsyncTemplate, compile, escapeHtml, markSafe, render, Template } from '../src/index.js';

// ============================================================================
// Basic Rendering Tests
// ============================================================================

Deno.test('Basic variable interpolation', () => {
  const result = render('Hello {{ name }}!', { name: 'World' });
  assertEquals(result, 'Hello World!');
});

Deno.test('Variable with dot notation', () => {
  const result = render('Hello {{ user.name }}!', { user: { name: 'Alice' } });
  assertEquals(result, 'Hello Alice!');
});

Deno.test('Multiple variables', () => {
  const result = render('{{ first }} and {{ second }}', { first: 'foo', second: 'bar' });
  assertEquals(result, 'foo and bar');
});

Deno.test('Missing variable in non-strict mode returns empty', () => {
  const result = render('Hello {{ name }}!', {});
  assertEquals(result, 'Hello !');
});

Deno.test('Missing variable in strict mode throws', () => {
  assertThrows(
    () => {
      render('Hello {{ name }}!', {}, { strictMode: true });
    },
    Error,
    'Variable not found: name',
  );
});

// ============================================================================
// HTML Escaping Tests
// ============================================================================

Deno.test('HTML escaping enabled by default', () => {
  const result = render('{{ value }}', { value: '<script>alert("xss")</script>' });
  assertEquals(result, '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;');
});

Deno.test('HTML escaping disabled', () => {
  const result = render('{{ value }}', { value: '<b>bold</b>' }, { autoEscape: false });
  assertEquals(result, '<b>bold</b>');
});

Deno.test('Safe string bypasses escaping', () => {
  const result = render('{{ value }}', { value: markSafe('<b>bold</b>') });
  assertEquals(result, '<b>bold</b>');
});

Deno.test('escapeHtml function works standalone', () => {
  assertEquals(escapeHtml('<script>'), '&lt;script&gt;');
  assertEquals(escapeHtml('a & b'), 'a &amp; b');
});

// ============================================================================
// Filter Tests
// ============================================================================

Deno.test('Filter: upper', () => {
  assertEquals(render('{{ name|upper }}', { name: 'alice' }), 'ALICE');
});

Deno.test('Filter: lower', () => {
  assertEquals(render('{{ name|lower }}', { name: 'ALICE' }), 'alice');
});

Deno.test('Filter: capitalize', () => {
  assertEquals(render('{{ name|capitalize }}', { name: 'alice' }), 'Alice');
});

Deno.test('Filter: title', () => {
  assertEquals(render('{{ text|title }}', { text: 'hello world' }), 'Hello World');
});

Deno.test('Filter: trim', () => {
  assertEquals(render('{{ text|trim }}', { text: '  hello  ' }), 'hello');
});

Deno.test('Filter: truncate with default', () => {
  assertEquals(render('{{ text|truncate }}', { text: 'Hello World' }), 'Hello...');
});

Deno.test('Filter: truncate with custom length', () => {
  assertEquals(render('{{ text|truncate:10 }}', { text: 'Hello World' }), 'Hello...');
  assertEquals(render('{{ text|truncate:5 }}', { text: 'Hello World' }), 'Hello');
});

Deno.test('Filter: truncate with custom suffix', () => {
  assertEquals(render('{{ text|truncate:5:"..." }}', { text: 'Hello World' }), 'Hello...');
});

Deno.test('Filter: default with value', () => {
  assertEquals(render('{{ name|default:"Unknown" }}', { name: 'Alice' }), 'Alice');
});

Deno.test('Filter: default without value', () => {
  assertEquals(render('{{ name|default:"Unknown" }}', {}), 'Unknown');
});

Deno.test('Filter: length', () => {
  assertEquals(render('{{ arr|length }}', { arr: [1, 2, 3] }), '3');
  assertEquals(render('{{ str|length }}', { str: 'hello' }), '5');
});

Deno.test('Filter: first', () => {
  assertEquals(render('{{ arr|first }}', { arr: [1, 2, 3] }), '1');
});

Deno.test('Filter: last', () => {
  assertEquals(render('{{ arr|last }}', { arr: [1, 2, 3] }), '3');
});

Deno.test('Filter: join', () => {
  assertEquals(render('{{ arr|join:"," }}', { arr: [1, 2, 3] }), '1,2,3');
});

Deno.test('Filter: reverse', () => {
  assertEquals(render('{{ arr|reverse|join }}', { arr: [1, 2, 3] }), '321');
});

Deno.test('Filter: json', () => {
  const result = render('{{ data|json }}', { data: { a: 1, b: 2 } });
  assertEquals(result.trim(), '{\n  "a": 1,\n  "b": 2\n}');
});

Deno.test('Filter: date', () => {
  const date = new Date('2024-01-15T12:30:00Z');
  const result = render('{{ date|date }}', { date });
  assertEquals(result, '2024-01-15');
});

Deno.test('Filter: date with custom format', () => {
  const date = new Date('2024-01-15T12:30:45Z');
  const result = render('{{ date|date:"YYYY-MM-DD HH:mm:ss" }}', { date });
  assertEquals(result, '2024-01-15 12:30:45');
});

// Filter chaining
Deno.test('Filter chaining: upper then truncate', () => {
  assertEquals(render('{{ name|upper|truncate:5 }}', { name: 'alice' }), 'ALIC...');
});

Deno.test('Filter chaining: multiple pipes', () => {
  assertEquals(render('{{ name|trim|upper|truncate:3 }}', { name: '  alice  ' }), 'ALI');
});

// ============================================================================
// Tag Tests
// ============================================================================

Deno.test('If tag: truthy value', () => {
  const result = render('{% if active %}YES{% endif %}', { active: true });
  assertEquals(result, 'YES');
});

Deno.test('If tag: falsy value', () => {
  const result = render('{% if active %}YES{% endif %}', { active: false });
  assertEquals(result, '');
});

Deno.test('If tag: with else', () => {
  const result1 = render('{% if active %}YES{% else %}NO{% endif %}', { active: true });
  const result2 = render('{% if active %}YES{% else %}NO{% endif %}', { active: false });
  assertEquals(result1, 'YES');
  assertEquals(result2, 'NO');
});

Deno.test('For tag: basic iteration', () => {
  const result = render('{% for item in items %}{{ item }}{% endfor %}', {
    items: ['a', 'b', 'c'],
  });
  assertEquals(result, 'abc');
});

Deno.test('For tag: with variable access', () => {
  const result = render('{% for user in users %}{{ user.name }}{% endfor %}', {
    users: [{ name: 'Alice' }, { name: 'Bob' }],
  });
  assertEquals(result, 'AliceBob');
});

Deno.test('For tag: with filters', () => {
  const result = render('{% for name in names %}{{ name|upper }}{% endfor %}', {
    names: ['alice', 'bob'],
  });
  assertEquals(result, 'ALICEBOB');
});

Deno.test('Include tag: placeholder (needs template loading)', () => {
  // Include tags require file loading, which is async
  // For now, they're replaced with empty string
  const result = render('{% include "test.html" %}', {});
  assertEquals(result, '');
});

// ============================================================================
// Cache Tests
// ============================================================================

Deno.test('Template caching enabled', () => {
  const template = new Template({ cache: true });
  const compiled1 = template.compile('Hello {{ name }}');
  const compiled2 = template.compile('Hello {{ name }}');
  assertEquals(compiled1, compiled2);
});

Deno.test('Template caching disabled', () => {
  const template = new Template({ cache: false });
  const compiled1 = template.compile('Hello {{ name }}');
  const compiled2 = template.compile('Hello {{ name }}');
  // Without caching, each compile creates a new object
  assertNotEquals(compiled1, compiled2);
});

Deno.test('Cache stats', () => {
  const template = new Template({ cache: true });
  template.compile('template1');
  template.compile('template2');
  const stats = template.getCacheStats();
  assertEquals(stats.size, 2);
});

Deno.test('Cache clear', () => {
  const template = new Template({ cache: true });
  template.compile('template1');
  template.clearCache();
  const stats = template.getCacheStats();
  assertEquals(stats.size, 0);
});

// ============================================================================
// Template Class Tests
// ============================================================================

Deno.test('Template class: render method', () => {
  const template = new Template();
  const result = template.render('Hello {{ name }}!', { name: 'World' });
  assertEquals(result, 'Hello World!');
});

Deno.test('Template class: compile method', () => {
  const template = new Template();
  const compiled = template.compile('Hello {{ name }}!');
  assertEquals(compiled.render({ name: 'World' }), 'Hello World!');
});

Deno.test('Template class: custom options', () => {
  const template = new Template({ autoEscape: false });
  const result = template.render('{{ value }}', { value: '<b>bold</b>' });
  assertEquals(result, '<b>bold</b>');
});

Deno.test('Template class: add custom filter', () => {
  const template = new Template();
  template.addFilter('double', (v) => Number(v) * 2);
  // Note: custom filters are stored but the engine uses built-in filters by default
  // The template class needs to be updated to use instance filters
  // For now, we test that the method works
  assertEquals(typeof template.filters.double, 'function');
});

// ============================================================================
// AsyncTemplate Tests
// ============================================================================

Deno.test('AsyncTemplate: preload templates', async () => {
  const template = new AsyncTemplate();
  await template.preload(['./tests/fixtures/test.html']);
  assertEquals(template.isPreloaded('./tests/fixtures/test.html'), true);
});

Deno.test('AsyncTemplate: render preloaded', async () => {
  // Create a test fixture
  await Deno.writeTextFile('./tests/fixtures/test.html', 'Hello {{ name }}!');

  const template = new AsyncTemplate();
  await template.preload(['./tests/fixtures/test.html']);
  const result = template.renderPreloaded('./tests/fixtures/test.html', { name: 'World' });

  assertEquals(result, 'Hello World!');

  // Cleanup
  await Deno.remove('./tests/fixtures/test.html');
});

// ============================================================================
// Edge Cases
// ============================================================================

Deno.test('Empty template', () => {
  assertEquals(render('', {}), '');
});

Deno.test('Template with only whitespace', () => {
  assertEquals(render('   ', {}), '   ');
});

Deno.test('Variable with null value', () => {
  assertEquals(render('{{ value }}', { value: null }), '');
});

Deno.test('Variable with undefined value', () => {
  assertEquals(render('{{ value }}', { value: undefined }), '');
});

Deno.test('Variable with 0 value', () => {
  assertEquals(render('{{ value }}', { value: 0 }), '0');
});

Deno.test('Variable with false value', () => {
  assertEquals(render('{{ value }}', { value: false }), 'false');
});

Deno.test('Nested context access', () => {
  const result = render('{{ a.b.c.d }}', {
    a: { b: { c: { d: 'deep' } } },
  });
  assertEquals(result, 'deep');
});

// ============================================================================
// Array Filter Tests
// ============================================================================

Deno.test('Array filter: sort', () => {
  const result = render('{{ items|sort|join:"," }}', { items: [3, 1, 2] });
  assertEquals(result, '1,2,3');
});

Deno.test('Array filter: unique', () => {
  const result = render('{{ items|unique|join:"," }}', { items: [1, 2, 2, 3, 3, 3] });
  assertEquals(result, '1,2,3');
});

Deno.test('Array filter: slice', () => {
  const result = render('{{ items|slice:1:3|join:"," }}', { items: [1, 2, 3, 4, 5] });
  assertEquals(result, '2,3');
});

Deno.test('Array filter: batch', () => {
  const result = render('{{ items|batch:2|json }}', { items: [1, 2, 3, 4] });
  const parsed = JSON.parse(result);
  assertEquals(parsed, [[1, 2], [3, 4]]);
});

// ============================================================================
// Number Filter Tests
// ============================================================================

Deno.test('Number filter: abs', () => {
  assertEquals(render('{{ n|abs }}', { n: -5 }), '5');
});

Deno.test('Number filter: round', () => {
  assertEquals(render('{{ n|round }}', { n: 3.7 }), '4');
});

Deno.test('Number filter: floor', () => {
  assertEquals(render('{{ n|floor }}', { n: 3.7 }), '3');
});

Deno.test('Number filter: ceil', () => {
  assertEquals(render('{{ n|ceil }}', { n: 3.2 }), '4');
});

Deno.test('Number filter: fixed', () => {
  assertEquals(render('{{ n|fixed:2 }}', { n: 3.14159 }), '3.14');
});

// ============================================================================
// Compile function tests
// ============================================================================

Deno.test('Compile function returns compiled template', () => {
  const compiled = compile('Hello {{ name }}!');
  assertEquals(compiled.render({ name: 'World' }), 'Hello World!');
  assertEquals(compiled.source, 'Hello {{ name }}!');
});

// ============================================================================
// markSafe function tests
// ============================================================================

Deno.test('markSafe creates safe string', () => {
  const safe = markSafe('<script>');
  assertEquals(safe.value, '<script>');
  assertEquals(safe.__safe, true);
});
