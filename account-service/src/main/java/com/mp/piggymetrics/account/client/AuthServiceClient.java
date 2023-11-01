package com.mp.piggymetrics.account.client;

import com.mp.piggymetrics.account.domain.User;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@ApplicationScoped
@RegisterRestClient(configKey = "authServiceClient")
public interface AuthServiceClient {

    @POST
    @Path("auth/users")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response add(User user);

    @GET
    @Path("health/ready")
    @Produces(MediaType.APPLICATION_JSON)
    public Response ready();
}
