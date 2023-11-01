package com.mp.piggymetrics.account.client;

import com.mp.piggymetrics.account.domain.Account;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.rest.client.annotation.RegisterClientHeaders;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@ApplicationScoped
@RegisterRestClient(configKey = "statisticsServiceClient")
@RegisterClientHeaders
public interface StatisticsServiceClient {

    @PUT
    @Path("statistics/{accountName}")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response saveAccountStatistics(@PathParam("accountName") String accountName, Account account);

    @GET
    @Path("health/ready")
    @Produces(MediaType.APPLICATION_JSON)
    public Response ready();
}
