package com.mp.piggymetrics.auth.service;

import com.mp.piggymetrics.auth.domain.User;
import com.mp.piggymetrics.auth.repository.UserRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.metrics.MetricUnits;
import org.eclipse.microprofile.metrics.annotation.Counted;
import org.eclipse.microprofile.metrics.annotation.Gauge;
import org.eclipse.microprofile.metrics.annotation.Timed;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class UserServiceImpl implements UserService {

    private final Logger log = LoggerFactory.getLogger(getClass());

    @Inject
    private UserRepository repository;

    @Timed(name = "userCreateTime", absolute = true)
    @Counted(name = "userCreateCount", absolute = true)
    @Override
    public User add(User user) {

        List<User> users = repository.findByUsername(user.getUsername());
        if (!users.isEmpty()) {
            return null;
        }

        // TODO: role should be set by account-service when creating new account
        // TODO: define role Enum to encapsulate constant roles
        user.setRole("user");
        // TODO: encode password for security
        repository.save(user);

        log.info("new user has been created: {}", user.getUsername());
        return user;
    }

    @Timed(name = "userReadTime", absolute = true)
    @Counted(name = "userReadCount", absolute = true)
    @Override
    public User get(String name) {
        List<User> users = repository.findByUsername(name);
        return users.size() != 1 ? null : users.get(0);
    }

    @Override
    public List<User> getAll() {
        return repository.findAll().collect(Collectors.toList());
    }

    @Gauge(unit = MetricUnits.NONE,
            name = "userSizeGauge",
            absolute = true,
            description = "Number of users")
    @Override
    public long count() {
        return repository.count();
    }
}
