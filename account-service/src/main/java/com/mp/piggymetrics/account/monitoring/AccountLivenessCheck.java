package com.mp.piggymetrics.account.monitoring;

import com.mp.piggymetrics.account.controller.AccountResource;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;

@Liveness
@ApplicationScoped
public class AccountLivenessCheck implements HealthCheck {

    @Override
    public HealthCheckResponse call() {
        MemoryMXBean memBean = ManagementFactory.getMemoryMXBean();
        long memUsed = memBean.getHeapMemoryUsage().getUsed();
        long memMax = memBean.getHeapMemoryUsage().getMax();

        return HealthCheckResponse.named(AccountResource.class.getSimpleName() + "Liveness")
                .withData("memory used", memUsed).withData("memory max", memMax).status(memUsed < memMax * 0.9).build();
    }
}