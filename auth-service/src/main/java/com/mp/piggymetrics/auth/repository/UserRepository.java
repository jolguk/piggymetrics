package com.mp.piggymetrics.auth.repository;

import com.mp.piggymetrics.auth.domain.User;
import jakarta.data.repository.CrudRepository;
import jakarta.data.repository.Repository;

import java.util.List;

@Repository
public interface UserRepository extends CrudRepository<User, String> {
    List<User> findByUsername(String name);
}
