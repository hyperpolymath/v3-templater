// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
import { render } from './src/index.js';

console.log('Test 1 (truncate default):', render('{{ text|truncate }}', { text: 'Hello World' }));
console.log('Test 2 (truncate:10):', render('{{ text|truncate:10 }}', { text: 'Hello World' }));
console.log('Test 3 (truncate:5):', render('{{ text|truncate:5 }}', { text: 'Hello World' }));
console.log('Test 4 (truncate:5:"..."):', render('{{ text|truncate:5:"..." }}', { text: 'Hello World' }));
console.log('Test 5 (json):', render('{{ data|json }}', { data: { a: 1, b: 2 } }));
