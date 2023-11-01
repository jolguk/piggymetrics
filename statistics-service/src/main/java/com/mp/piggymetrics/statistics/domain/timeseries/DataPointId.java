package com.mp.piggymetrics.statistics.domain.timeseries;

import jakarta.nosql.Column;
import jakarta.nosql.Entity;

import java.util.Date;

@Entity
public class DataPointId {

    @Column
    private String account;

    @Column
    private Date date;

    public DataPointId() {

    }

    public DataPointId(String account, Date date) {
        this.account = account;
        this.date = date;
    }

    public String getAccount() {
        return account;
    }

    public void setAccount(String account) {
        this.account = account;
    }

    public Date getDate() {
        return date;
    }

    public void setDate(Date date) {
        this.date = date;
    }

    @Override
    public String toString() {
        return "DataPointId{" +
                "account='" + account + '\'' +
                ", date=" + date +
                '}';
    }
}
