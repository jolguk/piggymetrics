package com.mp.piggymetrics.statistics.client;

import com.google.common.collect.ImmutableMap;
import com.mp.piggymetrics.statistics.domain.Currency;
import com.mp.piggymetrics.statistics.domain.ExchangeRatesContainer;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.faulttolerance.Fallback;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import java.math.BigDecimal;

@ApplicationScoped
@RegisterRestClient(baseUri = "https://api.exchangeratesapi.io")
public interface ExchangeRatesClient {

    @GET
    @Path("latest")
    @Produces(MediaType.APPLICATION_JSON)
    @Fallback(fallbackMethod = "getRatesFallback")
    public ExchangeRatesContainer getRates(@QueryParam("base") Currency base);

    default ExchangeRatesContainer getRatesFallback(Currency base) {
        ExchangeRatesContainer container = new ExchangeRatesContainer();
        container.setBase(Currency.getBase());
        container.setRates(ImmutableMap.of(
                Currency.EUR.name(), new BigDecimal(0.934425),
                Currency.RUB.name(), new BigDecimal(96.564977),
                Currency.USD.name(), BigDecimal.ONE
        ));
        return container;
    }
}
