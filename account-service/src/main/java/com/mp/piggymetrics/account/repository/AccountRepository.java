package com.mp.piggymetrics.account.repository;

import com.mp.piggymetrics.account.domain.Account;
import jakarta.data.repository.CrudRepository;
import jakarta.data.repository.Repository;

import java.util.List;

@Repository
public interface AccountRepository extends CrudRepository<Account, String> {
    List<Account> findByName(String name);
}
