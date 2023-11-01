package com.mp.piggymetrics.auth.domain;

import jakarta.nosql.Column;
import jakarta.nosql.Entity;
import jakarta.nosql.Id;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Entity
public class User {

    @NotNull
    @Size(min = 3, max = 20)
    @Id
    private String username;

    @NotNull
    @Size(min = 6, max = 40)
    @Column
    private String password;

    @NotNull
    @Column
    private String role;

    public User() {

    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}
