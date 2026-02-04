Ich habe das problem mit dem c onsumer in plugin/neotest.lua lösen können. aber weiterhin:

wenn ich zb in diese datei nvim öffne:



import { describe, it, expect } from 'vitest';

import { add, divide, multiply } from '../../src/utils/math';

describe('math.add', () => {

  it('adds two positive numbers', () => {

    expect(add(2, 3)).toBe(5);

  });

  it('adds negative numbers', () => {

    expect(add(2, -3)).toBe(-1);

  });

  it('adds zero', () => {

    expect(add(5, 0)).toBe(5);

  });

});

describe('math.divide', () => {

  it('divides two numbers', () => {

    expect(divide(6, 3)).toBe(2);

  });

  it('throws on division by zero', () => {

    expect(() => divide(1, 0)).toThrow('division by zero');

  });

  it('handles negative divisor', () => {

    expect(divide(10, -2)).toBe(-5);

  });

});

describe('math.multiply', () => {

  it('multiplies two positive numbers', () => {

    expect(multiply(3, 4)).toBe(12);

  });

  it('multiplies by zero', () => {

    expect(multiply(5, 0)).toBe(0);

  });

  it('multiplies negative numbers', () => {

    expect(multiply(-2, -3)).toBe(6);

  });

});





wobei folgender projektsruktur ist:

vitest.config.json

tsconfig.json

tests\utils\math.test.ts

src\utils\math.ts

pnpm-workspace.yaml

pnpm-lock.yaml

package.json



import { defineConfig } from 'vitest/config';

import path from 'path';

export default defineConfig({

  test: {

    globals: true,

    environment: 'node',

    include: ['tests/**/*.test.{js,ts,jsx,tsx}'],

    watch: false,

    reporters: ['verbose'],

    coverage: {

      provider: 'v8',

      reporter: ['text', 'json', 'html'],

    },

  },

});





{

  "compilerOptions": {

    "target": "ES2022",

    "module": "ESNext",

    "lib": ["ES2022"],

    "moduleResolution": "bundler",

    "resolveJsonModule": true,

    "allowJs": true,

    "strict": true,

    "esModuleInterop": true,

    "skipLibCheck": true,

    "forceConsistentCasingInFileNames": true,

    "types": ["vitest/globals"]

  },

  "include": ["src/**/*", "tests/**/*"],

  "exclude": ["node_modules"]

}



{

  "name": "astro-neotest-demo",

  "version": "1.0.0",

  "type": "module",

  "scripts": {

    "test": "vitest run",

    "test:watch": "vitest",

    "test:ui": "vitest --ui"

  },

  "devDependencies": {

    "@types/node": "^20.11.0",

    "@vitest/ui": "^4.0.18",

    "typescript": "^5.3.3",

    "vitest": "^1.2.0"

  }

}





src/utils/mah.ts:

/**

 * Add two numbers.

 * @param a - First number

 * @param b - Second number

 * @returns Sum of a and b

 */

export function add(a: number, b: number): number {

  return a + b;

}

/**

 * Divide two numbers.

 * @param a - Numerator

 * @param b - Denominator

 * @returns Quotient or error

 * @throws Error if denominator is zero

 */

export function divide(a: number, b: number): number {

  if (b === 0) {

    throw new Error('division by zero');

  }

  return a / b;

}

/**

 * Multiply two numbers.

 * @param a - First number

 * @param b - Second number

 * @returns Product of a and b

 */

export function multiply(a: number, b: number): number {

  return a * b;

}





###



Dann bekome ich immer:

   Warn  14:21:59 notify.warn Neotest No tests found

   Warn  14:22:01 notify.warn Neotest No running process found

wobei ich aber mit 

:NeotetRunFile

die test alaufen lassen und mit putüput dann ausgeben kann:

 RUN  v1.6.1 B:/repos/temporary/astro-neotest-demo

 ✓ tests/utils/math.test.ts > math.add > adds two positive numbers

 ✓ tests/utils/math.test.ts > math.add > adds negative numbers

 ✓ tests/utils/math.test.ts > math.add > adds zero

 ✓ tests/utils/math.test.ts > math.divide > divides two numbers

 ✓ tests/utils/math.test.ts > math.divide > throws on division by zero

 ✓ tests/utils/math.test.ts > math.divide > handles negative divisor

 ✓ tests/utils/math.test.ts > math.multiply > multiplies two positive numbers

 ✓ tests/utils/math.test.ts > math.multiply > multiplies by zero

 ✓ tests/utils/math.test.ts > math.multiply > multiplies negative numbers

 Test Files  1 passed (1)

      Tests  9 passed (9)

   Start at  14:26:02

   Duration  712ms (transform 57ms, setup 0ms, collect 70ms, tests 5ms, environment 0ms, prepare 248ms)

JSON report written to C:/Users/Bernhard/AppData/Local/Temp/nvim.0/L06VYy/3.json



und

:NeotestDebugState 

ist

14:22:37 msg_showcmd :

   Info  14:27:02 notify.info [neotest.debug] === Neotest Debug State ===

Registered Adapters:

  • neotest-jest:B:\repos\temporary\astro-neotest-demo

  • neotest-go:B:\repos\temporary\example-plugin\go

  • neotest-vitest:B:\repos\temporary\templates\web\htmx

  • neotest-vitest:B:\repos\temporary\example-plugin\go

  • neotest-plenary:B:\repos\temporary\example-plugin

  • neotest-vitest:B:\repos\temporary\templates\web\bun_nest_next\frontend\public\cats

  • neotest-vitest:B:\repos\temporary\astro-neotest-demo

  • neotest-vitest:B:\repos\temporary\templates\web\bun_nest_next\frontend\public

  • neotest-vitest:B:\repos\temporary\templates\web\bun_nest_next\frontend

  • neotest-jest:B:\repos\temporary\templates\web\bun_nest_next\frontend

  • neotest-vitest:B:\repos\temporary

Current Buffer:

  Path: B:\repos\temporary\astro-neotest-demo\tests\utils\math.test.ts

  Filetype: typescript

Test Tree:

  Found: NO










