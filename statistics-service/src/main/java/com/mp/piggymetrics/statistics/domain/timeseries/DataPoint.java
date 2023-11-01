package com.mp.piggymetrics.statistics.domain.timeseries;

import com.mp.piggymetrics.statistics.repository.converter.DataPointIdConverter;
import jakarta.nosql.Column;
import jakarta.nosql.Entity;
import jakarta.nosql.Id;
import org.eclipse.jnosql.mapping.Convert;

import java.util.Set;

/**
 * Represents daily time series data point containing
 * current account state
 */
@Entity
public class DataPoint {

    @Id
    @Convert(DataPointIdConverter.class)
    private DataPointId id;

    @Column
    private Set<ItemMetric> incomes;

    @Column
    private Set<ItemMetric> expenses;

    @Column
    private Set<ItemMetric> statistics;

    @Column
    private Set<ItemMetric> rates;

    public DataPointId getId() {
        return id;
    }

    public void setId(DataPointId id) {
        this.id = id;
    }

    public Set<ItemMetric> getIncomes() {
        return incomes;
    }

    public void setIncomes(Set<ItemMetric> incomes) {
        this.incomes = incomes;
    }

    public Set<ItemMetric> getExpenses() {
        return expenses;
    }

    public void setExpenses(Set<ItemMetric> expenses) {
        this.expenses = expenses;
    }

    public Set<ItemMetric> getStatistics() {
        return statistics;
    }

    public void setStatistics(Set<ItemMetric> statistics) {
        this.statistics = statistics;
    }

    public Set<ItemMetric> getRates() {
        return rates;
    }

    public void setRates(Set<ItemMetric> rates) {
        this.rates = rates;
    }
}
