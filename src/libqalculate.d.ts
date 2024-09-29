interface CalculationResult {
  /** A HTML string containing the parsed & formatted calculation input */
  input: string;
  /** A HTML string containing the formatted calculation result */
  output: string;
  /** Warnings or error messages which were thrown during calculation */
  messages: string[];
  /**
   * In case the calculation input contained a `plot` command, the resulting plot data
   * `commands` contains the plot commands intended for gnuplot, including curve IDs and labels
   * `data` contains the actual points for each curve ID.
   *     The points are stored in a string, one point per line, x & y coordinates separated by a space
  */
  plotData: { data: Record<string, string>; commands: string } | undefined;
}

interface MainModule {
  /**
   * Runs a calculation
   * @argument calculation Input as string, for example `"1 m + 5 mm"`
   * @argument timeout Calculation timeout in milliseconds; 0 for no timeout
   * @argument optionFlags optional options, will be changed/removed soon; for now just enter 0
   * @returns the calculation result
   */
  calculate(calculation: string, timeout: number, optionFlags: number): CalculationResult;

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

  /** returns the library feature version as number; */
  version(): number;
}

interface LoadingOptions {
  locateFile(prefix: string, path: string): string;
}

export default function loadLibqalculate(loadingOptions?: LoadingOptions): Promise<MainModule>;
