package com.mp.piggymetrics.statistics.service;

import com.google.common.collect.ImmutableSet;
import com.mp.piggymetrics.statistics.domain.*;
import com.mp.piggymetrics.statistics.domain.timeseries.DataPoint;
import com.mp.piggymetrics.statistics.domain.timeseries.DataPointId;
import com.mp.piggymetrics.statistics.domain.timeseries.ItemMetric;
import com.mp.piggymetrics.statistics.repository.DataPointRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.metrics.MetricUnits;
import org.eclipse.microprofile.metrics.annotation.Counted;
import org.eclipse.microprofile.metrics.annotation.Gauge;
import org.eclipse.microprofile.metrics.annotation.Timed;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@ApplicationScoped
public class StatisticsServiceImpl implements StatisticsService {

    private final Logger log = LoggerFactory.getLogger(getClass());

    @Inject
    private DataPointRepository repository;

    @Inject
    private ExchangeRatesService ratesService;

    @Timed(name = "statisticsReadTime", absolute = true)
    @Counted(name = "statisticsReadCount", absolute = true)
    @Override
    public List<DataPoint> findByAccountName(String accountName) {
        return repository.findByIdAccount(accountName);
    }

    @Timed(name = "statisticsSaveTime", absolute = true)
    @Counted(name = "statisticsSaveCount", absolute = true)
    @Override
    public DataPoint save(String accountName, Account account) {

        Date date = Date.from(LocalDate.now().atStartOfDay().atZone(ZoneId.systemDefault()).toInstant());
        DataPointId pointId = new DataPointId(accountName, date);

        Set<ItemMetric> incomes = account.getIncomes().stream()
                .map(this::createItemMetric)
                .collect(Collectors.toSet());

        Set<ItemMetric> expenses = account.getExpenses().stream()
                .map(this::createItemMetric)
                .collect(Collectors.toSet());

        /*
         * TODO: verify if the following workaround is still needed after updating
         * Workaround to update the existing entry as it always failed with exception
         * "org.bson.codecs.configuration.CodecConfigurationException: Can't find a codec for class org.jnosql.diana.api.document.DefaultDocument"
         * . Noticed that updating the existing entry whose id property is built-in
         * primitive type works well.
         */
        if (repository.findById(pointId).isPresent()) {
            repository.deleteById(pointId);
        }
        DataPoint dataPoint = new DataPoint();
        dataPoint.setId(pointId);
        dataPoint.setIncomes(incomes);
        dataPoint.setExpenses(expenses);
        dataPoint.setStatistics(createStatisticMetrics(incomes, expenses, account.getSaving()));
        dataPoint.setRates(ratesService.getCurrentRates().entrySet().stream()
                .map(e -> new ItemMetric(e.getKey().toString(), e.getValue())).collect(Collectors.toSet()));

        log.info("new datapoint has been created: {}", pointId);

        return repository.save(dataPoint);
    }

    private Set<ItemMetric> createStatisticMetrics(Set<ItemMetric> incomes, Set<ItemMetric> expenses, Saving saving) {

        BigDecimal savingAmount = ratesService.convert(saving.getCurrency(), Currency.getBase(), saving.getAmount());

        BigDecimal expensesAmount = expenses.stream()
                .map(ItemMetric::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal incomesAmount = incomes.stream()
                .map(ItemMetric::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return ImmutableSet.of(new ItemMetric("savingAmount", savingAmount),
                new ItemMetric("expensesAmount", expensesAmount), new ItemMetric("incomesAmount", incomesAmount));
    }

    /**
     * Normalizes given item amount to {@link Currency#getBase()} currency with
     * {@link TimePeriod#getBase()} time period
     */
    private ItemMetric createItemMetric(Item item) {

        BigDecimal amount = ratesService
                .convert(item.getCurrency(), Currency.getBase(), item.getAmount())
                .divide(item.getPeriod().getBaseRatio(), 4, RoundingMode.HALF_UP);

        return new ItemMetric(item.getTitle(), amount);
    }

    @Gauge(unit = MetricUnits.NONE,
            name = "statisticsSizeGauge",
            absolute = true,
            description = "The total number of statistics for all of accounts")
    @Override
    public long count() {
        return repository.count();
    }
}
