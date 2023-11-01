package com.mp.piggymetrics.account.domain;

import com.mp.piggymetrics.account.repository.converter.BigDecimalConverter;
import jakarta.nosql.Column;
import jakarta.nosql.Entity;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.eclipse.jnosql.mapping.Convert;

import java.math.BigDecimal;

@Entity
public class Item {

    @NotNull
    @Size(min = 1, max = 20)
    @Column
    private String title;

    @NotNull
    @Column
    @Convert(BigDecimalConverter.class)
    private BigDecimal amount;

    @NotNull
    @Column
    private Currency currency;

    @NotNull
    @Column
    private TimePeriod period;

    @NotNull
    @Column
    private String icon;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public Currency getCurrency() {
        return currency;
    }

    public void setCurrency(Currency currency) {
        this.currency = currency;
    }

    public TimePeriod getPeriod() {
        return period;
    }

    public void setPeriod(TimePeriod period) {
        this.period = period;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }
}
