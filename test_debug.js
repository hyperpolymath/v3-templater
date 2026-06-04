// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
import { parseFilters } from './src/engine.js';

const tests = [
  'text|truncate',
  'text|truncate:10',
  'text|truncate:5',
  'text|truncate:5:"..."',
  'arr|join:","',
  'name|default:"Unknown"',
  'data|json',
];

for (const test of tests) {
  const result = parseFilters(test);
  console.log(`Input: ${test}`);
  console.log(`  Expression: ${result.expression}`);
  console.log(`  Filters:`, JSON.stringify(result.filters));
  console.log();
}
