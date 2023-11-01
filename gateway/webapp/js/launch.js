var global = {
    mobileClient: false,
    savePermit: true,
    usd: 0,
    eur: 0
};

/**
 * Oauth2
 */

function requestOauthToken(username, password) {

	var success = false;

	$.ajax({
		url: '/api/auth/login',
		datatype: 'json',
        type: 'post',
        contentType: 'application/json',
        data: JSON.stringify({
			username: username,
			password: password
		}),
		async: false,
		success: function (data) {
			localStorage.setItem('token', data.access_token);
			success = true;
		},
		error: function () {
			removeOauthTokenFromStorage();
		}
	});

	return success;
}

function getOauthTokenFromStorage() {
	return localStorage.getItem('token');
}

function removeOauthTokenFromStorage() {
    return localStorage.removeItem('token');
}

/**
 * Current account
 */

function getCurrentAccount() {

	var token = getOauthTokenFromStorage();
	var account = null;

	if (token) {
		$.ajax({
			url: '/api/accounts/current',
			datatype: 'json',
			type: 'get',
			headers: {'Authorization': 'Bearer ' + token},
			async: false,
			success: function (data) {
				account = data;
			},
			error: function () {
				removeOauthTokenFromStorage();
			}
		});
	}

	return account;
}

$(window).load(function(){

	if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
		FastClick.attach(document.body);
        global.mobileClient = true;
	}

    $.ajax({
        url: '/api/statistics/rates',
        datatype: 'json',
        type: 'get',
        async: false,
        success: function (data) {
            global.eur = data.RUB / data.EUR;
            global.usd = data.RUB;
        }
    });

	var account = getCurrentAccount();

	if (account) {
		showGreetingPage(account);
	} else {
		showLoginForm();
	}
});

function showGreetingPage(account) {
    initAccount(account);
	var userAvatar = $("<img />").attr("src","images/userpic.jpg");
	$(userAvatar).load(function() {
		setTimeout(initGreetingPage, 500);
	});
}

function showLoginForm() {
	$("#loginpage").show();
	$("#frontloginform").focus();
	setTimeout(initialShaking, 700);
}