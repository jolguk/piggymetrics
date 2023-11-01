package com.mp.piggymetrics.account.service;

import com.mp.piggymetrics.account.domain.Account;
import com.mp.piggymetrics.account.domain.Currency;
import com.mp.piggymetrics.account.domain.Saving;
import com.mp.piggymetrics.account.domain.User;
import com.mp.piggymetrics.account.repository.AccountRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.metrics.MetricUnits;
import org.eclipse.microprofile.metrics.annotation.Counted;
import org.eclipse.microprofile.metrics.annotation.Gauge;
import org.eclipse.microprofile.metrics.annotation.Timed;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class AccountServiceImpl implements AccountService {

    private final Logger log = LoggerFactory.getLogger(getClass());

    @Inject
    private AccountRepository repository;

    @Timed(name = "accountCreateTime", absolute = true)
    @Counted(name = "accountCreateCount", absolute = true)
    @Override
    public Account add(User user) {
        Saving saving = new Saving();
        saving.setAmount(new BigDecimal(0));
        saving.setCurrency(Currency.getDefault());
        saving.setInterest(new BigDecimal(0));
        saving.setDeposit(false);
        saving.setCapitalization(false);

        Account account = new Account();
        account.setName(user.getUsername());
        account.setLastSeen(ZonedDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT));
        account.setSaving(saving);

        repository.save(account);

        log.info("new account has been created: {}", account.getName());

        return account;
    }

    @Timed(name = "accountUpdateTime", absolute = true)
    @Counted(name = "accountUpdateCount", absolute = true)
    @Override
    public Account save(String name, Account update) {
        List<Account> accounts = repository.findByName(name);
        if (accounts.size() != 1) {
            return null;
        }

        Account account = accounts.get(0);
        account.setIncomes(update.getIncomes());
        account.setExpenses(update.getExpenses());
        account.setSaving(update.getSaving());
        account.setNote(update.getNote());
        account.setLastSeen(ZonedDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT));
        repository.save(account);

        log.info("account {} changes has been saved", name);

        return account;
    }

    @Timed(name = "accountReadTime", absolute = true)
    @Counted(name = "accountReadCount", absolute = true)
    @Override
    public Account get(String name) {
        List<Account> accounts = repository.findByName(name);
        return accounts.size() != 1 ? null : accounts.get(0);
    }

    @Override
    public List<Account> getAll() {
        return repository.findAll().collect(Collectors.toList());
    }

    @Override
    public void delete(String id) {
        repository.deleteById(id);
    }

    @Gauge(unit = MetricUnits.NONE,
            name = "accountSizeGauge",
            absolute = true,
            description = "Number of accounts")
    @Override
    public long count() {
        return repository.count();
    }

}
