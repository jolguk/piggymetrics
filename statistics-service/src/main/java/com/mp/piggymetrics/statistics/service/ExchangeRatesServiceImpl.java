package com.mp.piggymetrics.statistics.service;

import com.google.common.collect.ImmutableMap;
import com.mp.piggymetrics.statistics.client.ExchangeRatesClient;
import com.mp.piggymetrics.statistics.domain.Currency;
import com.mp.piggymetrics.statistics.domain.ExchangeRatesContainer;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.Map;

@ApplicationScoped
public class ExchangeRatesServiceImpl implements ExchangeRatesService {

    private static final Logger log = LoggerFactory.getLogger(ExchangeRatesServiceImpl.class);

    private ExchangeRatesContainer container;

    @Inject
    @RestClient
    private ExchangeRatesClient client;

    /**
     * {@inheritDoc}
     */
    @Override
    public Map<Currency, BigDecimal> getCurrentRates() {

        if (container == null || !container.getDate().equals(LocalDate.now())) {
            container = client.getRates(Currency.getBase());
            log.info("exchange rates has been updated: {}", container);
        }

        return ImmutableMap.of(
                Currency.EUR, container.getRates().get(Currency.EUR.name()),
                Currency.RUB, container.getRates().get(Currency.RUB.name()),
                Currency.USD, BigDecimal.ONE
        );
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public BigDecimal convert(Currency from, Currency to, BigDecimal amount) {

        Map<Currency, BigDecimal> rates = getCurrentRates();
        BigDecimal ratio = rates.get(to).divide(rates.get(from), 4, RoundingMode.HALF_UP);

        return amount.multiply(ratio);
    }
}
