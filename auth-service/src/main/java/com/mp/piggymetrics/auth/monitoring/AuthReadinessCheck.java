package com.mp.piggymetrics.auth.monitoring;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import org.eclipse.microprofile.health.Readiness;

import com.mp.piggymetrics.auth.controller.AuthResource;
import com.mp.piggymetrics.auth.service.UserService;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;

@Readiness
@ApplicationScoped
public class AuthReadinessCheck implements HealthCheck {

	@Inject
	private UserService userManager;

	@Override
	public HealthCheckResponse call() {
		return isReady()
				? HealthCheckResponse.named(AuthResource.class.getSimpleName() + "Readiness")
						.withData("default server", "available").up().build()
				: HealthCheckResponse.named(AuthResource.class.getSimpleName() + "Readiness")
						.withData("default server", "not available").down().build();
	}

	private boolean isReady() {
		try {
			userManager.count();
			return true;
		} catch (Exception e) {
			return false;
		}
	}
}