package com.mp.piggymetrics.auth.monitoring;

import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;

import jakarta.enterprise.context.ApplicationScoped;
import com.mp.piggymetrics.auth.controller.AuthResource;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

@Liveness
@ApplicationScoped
public class AuthLivenessCheck implements HealthCheck {

	@Override
	public HealthCheckResponse call() {
		MemoryMXBean memBean = ManagementFactory.getMemoryMXBean();
		long memUsed = memBean.getHeapMemoryUsage().getUsed();
		long memMax = memBean.getHeapMemoryUsage().getMax();

		return HealthCheckResponse.named(AuthResource.class.getSimpleName() + "Liveness")
				.withData("memory used", memUsed).withData("memory max", memMax).status(memUsed < memMax * 0.9).build();
	}
}