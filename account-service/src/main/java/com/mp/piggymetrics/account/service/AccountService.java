package com.mp.piggymetrics.account.service;

import java.util.List;

import com.mp.piggymetrics.account.domain.Account;
import com.mp.piggymetrics.account.domain.User;

public interface AccountService {

    Account add(User user);
    
    Account save(String name, Account update);

	Account get(String name);

    List<Account> getAll();

    void delete(String id);
    
    long count();
}
