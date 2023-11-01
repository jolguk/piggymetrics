package com.mp.piggymetrics.auth.controller;

import com.ibm.websphere.security.jwt.Claims;
import com.ibm.websphere.security.jwt.JwtBuilder;
import com.mp.piggymetrics.auth.domain.User;
import com.mp.piggymetrics.auth.service.UserService;

import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.json.Json;
import jakarta.json.JsonObjectBuilder;
import jakarta.annotation.security.RolesAllowed;

import org.eclipse.microprofile.jwt.JsonWebToken;

/**
 * The AuthResource is responsible for providing JWTs (users-token) to the
 * caller who is already logged-in, so they call other end-points with the
 * returned token
 */
@Path("")
@RequestScoped
public class AuthResource {

  @Inject
  private UserService userManager;
  
  @Inject
  private JsonWebToken jwtPrincipal;

  @POST
  @Path("/login")
  @Consumes(MediaType.APPLICATION_JSON)
  public Response loginUser(User user) {
    User dbUser = userManager.get(user.getUsername());
    if (null == dbUser) {
      return Response.status(Status.BAD_REQUEST).entity("User not found!").build();
    }
    if (!dbUser.getPassword().equals(user.getPassword())) {
      return Response.status(Status.FORBIDDEN).entity("Password incorrect!").build();
    }

    String jwtTokenString = null;
    try {
      jwtTokenString = JwtBuilder.create("jwtAuthUserBuilder").claim(Claims.SUBJECT, "authenticated")
          .claim("upn", dbUser.getUsername()) /* MP-JWT defined subject claim */
          .claim("groups", dbUser.getRole()) /* MP-JWT defined group, seems Liberty makes an array from a comma separated list */
          .buildJwt().compact();
    } catch (Throwable t) {
      return Response.status(Status.INTERNAL_SERVER_ERROR).entity("Erorr building authorization token").build();
    }

    JsonObjectBuilder builder = Json.createObjectBuilder();
    builder.add("access_token", jwtTokenString);

    return Response.ok(builder.build()).header(HttpHeaders.AUTHORIZATION, "Bearer " + jwtTokenString)
        .header("Access-Control-Expose-Headers", HttpHeaders.AUTHORIZATION).build();
  }

  @GET
  @Path("users/{name}")
  @RolesAllowed({ "user", "admin" })
  @Produces(MediaType.APPLICATION_JSON)
  public Response get(@PathParam("name") String name) {
    if (this.jwtPrincipal.getGroups().contains("admin") || this.jwtPrincipal.getName().equals(name)) {
    	return Response.ok(userManager.get(name)).build();
	}
	return Response.status(Status.UNAUTHORIZED).entity("No permission granted to view other user!").build();
  }
  
  @GET
  @Path("users")
  @RolesAllowed({ "admin" })
  @Produces(MediaType.APPLICATION_JSON)
  public Response getAll(@PathParam("name") String name) {
    return Response.ok(userManager.getAll()).build();
  }

  @POST
  @Path("users")
  @Consumes(MediaType.APPLICATION_JSON)
  public Response add(User user) {
    User savedUser = userManager.add(user);

    return Response
        .created(UriBuilder.fromResource(this.getClass()).path(String.valueOf(savedUser.getUsername())).build()).build();
  }
}
