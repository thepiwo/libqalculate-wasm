# libqalculate-wasm

libqalculate-wasm is a WebAssembly (WASM) port of the [libqalculate](https://github.com/Qalculate/libqalculate/) library, a powerful calculation library.

WARNING: This is a first, rough preview version. The API _will_ change.

## Installation

To install libqalculate-wasm, you can use npm:

```bash
npm install libqalculate-wasm
```

## Usage

Here is a simple example of how to use libqalculate-wasm in your project:

```javascript
import loadLibqalculate from "libqalculate-wasm";

const libqalculate = await loadLibqalculate();
const result = libqalculate.calculate(
  "2 + 2",
  300 /* timeout */,
  0 /* option flags */
);

document.getElementById("result").innerHTML = result.output;
```

`loadLibqalculate` loads the ~5 MB large WebAssembly file, which is included in the node module but must be served on the webserver.
One way to achieve that, is to copy it into your public folder during package installation, by adding the following to your `package.json` file:

```JSON
{
  ...
  "scripts": {
    "dev": ...,
    ...,
    "postinstall": "cp ./node_modules/libqalculate-wasm/libqalculate.wasm ./public/libqalculate.wasm"
  },
  ...
}
```

Depending on the framework/bundler in use, you might have to specify the location where the wasm file can be loaded, by adapting the `loadOptions` of `loadLibqalculate`:

```javascript
const libqalculate = await loadLibqalculate({
  locateFile: (path: string, prefix: string) => `/${path}`,
});
```

(example in case of the libqalculate.wasm file being served from the root directory)

## API

WARNING: This is a first, rough preview version. The API _will_ change (see the [Changelog](CHANGELOG.md)).

First, libqalculate has to be loaded by using `loadLibqalculate`, the default export of this library.

```TS
interface LoadingOptions {
  locateFile(prefix: string, path: string): string;
}

export default function loadLibqalculate(loadingOptions?: LoadingOptions): Promise<MainModule>;
```

The `MainModule` provides several functions for interaction with libqalculate:

```TS
/**
 * Runs a calculation
 * @argument calculation: Input as string, for example `"1 m + 5 mm"`
 * @argument timeout: Calculation timeout in milliseconds; 0 for no timeout
 * @argument optionFlags: optional options, will be changed/removed soon; for now just enter 0
 * @returns the calculation result
 */
calculate(calculation: string, timeout: number, optionFlags: number): CalculationResult;

interface CalculationResult {
  /** A HTML string containing the parsed & formatted calculation input */
  input: string;
  /** A HTML string containing the formatted calculation result */
  output: string;
  /** Warnings or error messages which were thrown during calculation */
  messages: string[];
  /**
   *  In case the calculation input contained a `plot` command, the resulting plot data
   *  `commands` contains the plot commands intended for gnuplot, including curve IDs and labels
   *  `data` contains the actual points for each curve ID.
   *      The points are stored in a string, one point per line, x & y coordinates separated by a space
  */
  plotData: { data: Record<string, string>; commands: string } | undefined;
}


/**
 * Provide libqalculate with new exchange rates.
 * @param currencyData The exchange rates; for example: [{ name: 'USD', value: 1.2345 }] => 1 USD = 1.2345 EUR
 * @param baseCurrency The currency relative to which the exchange rates are given; currently only `EUR` is supported.
 * @param showWarning Whether to show warnings about outdated exchange rates
 * @returns whether the update was successful
 */
updateCurrencyValues(currencyData: Array<{ name: string, value: string }>, baseCurrency: 'EUR', showWarning: boolean): boolean;


/**
 * Returns all variables/constants known to libqalculate
 */
getVariables(): Array<{
/** name of the variable, for example "π" */
name: string;
/** description, for example "Archimedes' Constant (pi)" */
description: string;
/** aliases of the variable, for example ["π", "pi"] */
aliases: string[];
}>;


/**
 * Set options with command strings like `angle 2`, `unit on` or `limit implicit multiplication off`
 * For a list of possible options, see https://qalculate.github.io/manual/qalc.html#SETTINGS
 */
set_option(str: string): boolean;
```

## Usage example with React & support for Server Components

```TSX
'use client';

import { use, useState } from 'react';
import loadLibqalculate from 'libqalculate-wasm';

// Since it's interactive, let's not load libqalculate during SSR.
const libqalculatePromise = typeof window !== 'undefined' ? loadLibqalculate({
    // important: libqalculate.wasm has to be copied to the public folder
    locateFile: (path: string) => `/${path}`, // Absolute URL
}) : Promise.resolve(null);

export function Calculator() {
    const [input, setInput] = useState('');
    const [latexInput, setLatexInput] = useState('');
    const libqalculate = use(libqalculatePromise);

    const calculation = input ? libqalculate?.calculate(input, 0, 0) : null;
    const plotDataset = calculation?.plotData ? processPlotData(calculation.plotData) : null;
    return (
        <div>
            <input title="Calculation" className="border-gray-600 border-2" value={input} onChange={(e) => setInput(e.currentTarget.value)} />
            {calculation && <div><span dangerouslySetInnerHTML={{ __html: calculation.input }} /> = <span dangerouslySetInnerHTML={{ __html: calculation.output }} /></div>}
        </div>
    );
}
```

## Development

Emscripten is being used for compiling [libqalculate.cc](src/libqalculate.cc) (the glue between libqalculate and JavaScript). A docker image fulfilling the dependencies and including the precompiled libraries is available at [GitHub's container registry](ghcr.io/stephtr/libqalculate-wasm), automatically built from this repository's [Dockerfile](Dockerfile).

For compilation, just run `./build-wasm.sh`. It automatically spins up the docker container and generates the libqalculate.wasm/.js files.

## License

This project is licensed under the GPL-3.0 License.
