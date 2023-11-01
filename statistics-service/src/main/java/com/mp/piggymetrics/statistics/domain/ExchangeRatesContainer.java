package com.mp.piggymetrics.statistics.domain;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;

public class ExchangeRatesContainer {

	private LocalDate date = LocalDate.now();

	private Currency base;

	private Map<String, BigDecimal> rates;

	public LocalDate getDate() {
		return date;
	}

	public Currency getBase() {
		return base;
	}

	public void setBase(Currency base) {
		this.base = base;
	}

	public Map<String, BigDecimal> getRates() {
		return rates;
	}

	public void setRates(Map<String, BigDecimal> rates) {
		this.rates = rates;
	}

	@Override
	public String toString() {
		return "RateList{" +
				"date=" + date +
				", base=" + base +
				", rates=" + rates +
				'}';
	}
}
