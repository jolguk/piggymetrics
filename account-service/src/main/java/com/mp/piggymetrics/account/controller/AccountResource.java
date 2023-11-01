package com.mp.piggymetrics.account.controller;

import com.mp.piggymetrics.account.client.AuthServiceClient;
import com.mp.piggymetrics.account.client.StatisticsServiceClient;
import com.mp.piggymetrics.account.domain.Account;
import com.mp.piggymetrics.account.domain.User;
import com.mp.piggymetrics.account.service.AccountService;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.core.UriBuilder;
import org.eclipse.microprofile.jwt.JsonWebToken;
import org.eclipse.microprofile.rest.client.inject.RestClient;

@Path("")
@RequestScoped
public class AccountResource {

    @Inject
    private AccountService accountManager;

    @Inject
    @RestClient
    private StatisticsServiceClient statisticsClient;

    @Inject
    @RestClient
    private AuthServiceClient authClient;

    @Inject
    private JsonWebToken jwtPrincipal;

    @GET
    @Path("current")
    @RolesAllowed({"user", "admin"})
    @Produces(MediaType.APPLICATION_JSON)
    public Response getCurrent() {
        return Response.ok(accountManager.get(this.jwtPrincipal.getName())).build();
    }

    @PUT
    @Path("current")
    @RolesAllowed({"user", "admin"})
    @Consumes(MediaType.APPLICATION_JSON)
    public Response updateCurrent(Account update) {
        Account account = accountManager.save(this.jwtPrincipal.getName(), update);
        statisticsClient.saveAccountStatistics(this.jwtPrincipal.getName(), account);

        return Response.ok().build();
    }

    @GET
    @RolesAllowed({"admin"})
    @Produces(MediaType.APPLICATION_JSON)
    public Response getAll() {
        return Response.ok(accountManager.getAll()).build();
    }

    @GET
    @Path("{name}")
    @RolesAllowed({"user", "admin"})
    @Produces(MediaType.APPLICATION_JSON)
    public Response get(@PathParam("name") String name) {
        if (this.jwtPrincipal.getGroups().contains("admin") || this.jwtPrincipal.getName().equals(name)) {
            return Response.ok(accountManager.get(name)).build();
        }
        return Response.status(Status.UNAUTHORIZED).entity("No permission granted to view other account!").build();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response add(User user) {
        authClient.add(user);
        Account savedAccount = accountManager.add(user);

        return Response.created(
                        UriBuilder.fromResource(this.getClass()).path(String.valueOf(savedAccount.getName())).build())
                .build();
    }

}
