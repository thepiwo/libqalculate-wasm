#include <emscripten/bind.h>
#include <libqalculate/Calculator.h>
#include <libqalculate/Variable.h>

using namespace emscripten;

EvaluationOptions evalops;
PrintOptions printops;

#include "settings.h"

val lastPlotData;

val calculate(std::string calculation, int timeout = 500, int optionFlags = 0)
{
	CALCULATOR->clearMessages();
	lastPlotData = val::null();

	calculation = CALCULATOR->unlocalizeExpression(calculation, evalops.parse_options);
	std::string parsed_str;
	bool resultIsComparison;
	auto result = CALCULATOR->calculateAndPrint(calculation, timeout, evalops, printops, &parsed_str);

	val ret = val::object();
	ret.set("input", parsed_str);
	ret.set("output", result);

	val messages = val::array();
	ret.set("messages", messages);
	CalculatorMessage *message;
	if ((message = CALCULATOR->message()))
	{
		auto msgType = message->type();
		std::string severity = msgType == MESSAGE_INFORMATION ? "Info" : msgType == MESSAGE_WARNING ? "Warning"
																									: "Error";
		messages.call<void>("push", severity + ": " + message->message());
	}

	if (!lastPlotData.isNull())
	{
		ret.set("plotData", lastPlotData);
	}

	return ret;
}

val getVariables()
{
	auto variables = val::array();
	for (auto &variable : CALCULATOR->variables)
	{
		if (!variable->isKnown() || variable->isHidden())
			continue;

		auto info = val::object();
		info.set("name", variable->preferredDisplayName(true, true).name);
		info.set("description", variable->title(false, true));
		auto nameCount = variable->countNames();
		auto aliases = val::array();
		if (nameCount < 1)
		{
			aliases.call<void>("push", variable->preferredDisplayName(true, true).name);
		}
		else
		{
			for (size_t i = 1; i <= nameCount; i++)
			{
				aliases.call<void>("push", variable->getName(i).name);
			}
		}
		info.set("aliases", aliases);
		variables.call<void>("push", info);
	}
	return variables;
}

bool updateCurrencyValues(const val &currencyData, std::string baseCurrency, bool showWarning)
{
	int errorCode = 0;

	auto u1 = CALCULATOR->getActiveUnit(baseCurrency);
	if (u1 != CALCULATOR->u_euro)
	{
		return 1;
	}

	for (int i = 0; i < currencyData["length"].as<int>(); i++)
	{
		emscripten::val data = currencyData[i];
		auto name = data["name"].as<std::string>();
		auto value = data["value"].as<std::string>();
		auto u2 = CALCULATOR->getActiveUnit(name);
		if (!u2)
		{
			u2 = CALCULATOR->addUnit(new AliasUnit(_("Currency"), name, "", "", "", CALCULATOR->u_euro, "1", 1, "", false, true));
		}
		else if (!u2->isCurrency())
		{
			errorCode = 2;
			continue;
		}

		((AliasUnit *)u2)->setBaseUnit(u1);
		((AliasUnit *)u2)->setExpression(value);
		u2->setApproximate();
		u2->setPrecision(-2);
		u2->setChanged(false);
	}

	CALCULATOR->setExchangeRatesWarningEnabled(showWarning);
	CALCULATOR->loadGlobalCurrencies();

	return errorCode == 0;
}

int main()
{
	new Calculator();
	CALCULATOR->loadGlobalDefinitions();
	printops.use_unicode_signs = false;
	printops.interval_display = INTERVAL_DISPLAY_SIGNIFICANT_DIGITS;
	printops.base_display = BASE_DISPLAY_NONE;
	printops.digit_grouping = DIGIT_GROUPING_NONE;
	printops.indicate_infinite_series = true;
	printops.exp_display = EXP_LOWERCASE_E;
	evalops.parse_options.angle_unit = ANGLE_UNIT_RADIANS;
	evalops.parse_options.unknowns_enabled = false;
	return 0;
}

std::string info()
{
	return "libqalculate by Hanna Knutsson, wrapped & compiled by Stephan Troyer";
}

int version()
{
	return 1;
}

std::string qalc_gnuplot_data_dir()
{
	return "";
}
bool qalc_invoke_gnuplot(
	std::vector<std::pair<std::string, std::string>> data_files,
	std::string commands, std::string extra, bool persist)
{
	val plot = val::object();
	val data = val::object();
	plot.set("data", data);
	plot.set("commands", commands);
	for (auto file : data_files)
	{
		data.set(file.first, file.second);
	}
	lastPlotData = plot;
	return true;
}

EMSCRIPTEN_BINDINGS(Calculator)
{
	function("calculate", &calculate);
	function("info", &info);
	function("version", &version);
	function("getVariables", &getVariables);
	function("set_option", &set_option);
	function("updateCurrencyValues", &updateCurrencyValues);
}
