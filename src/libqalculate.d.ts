interface CalculationResult {
  input: string;
  output: string;
  messages: string[];
  plotData: { data: Record<string, string>; commands: string } | undefined;
}

interface MainModule {
  calculate(calculation: string, timeout: number, optionFlags: number): CalculationResult;
  info(): string;
  version(): number;
  getVariables(): Array<{
    name: string;
    description: string;
    aliases: string[];
  }>;
  set_option(str: string): boolean;
  updateCurrencyValues(currencyData: Array<{ name: string, value: string }>, baseCurrency: string, showWarning: boolean): boolean;
}

export default function MainModuleFactory(loadingOptions?: any): Promise<MainModule>;
