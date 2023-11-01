package com.mp.piggymetrics.auth.service;

import java.util.List;

import com.mp.piggymetrics.auth.domain.User;

public interface UserService {

    User add(User user);

	User get(String name);
	
	List<User> getAll();
	
	long count();
}
