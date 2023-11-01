package com.mp.piggymetrics.account.client;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;

public class SSLAffirmativeHostnameVerifier implements HostnameVerifier {
    @Override
    public boolean verify(String hostname, SSLSession session) {
        /**
         * Previously there was an issue (https://github.com/OpenLiberty/open-liberty/issues/11108) which complained that
         * the custom "HostnameVerifier" is not honored in mpRestClient-1.3.
         * The issue was fixed by https://github.com/OpenLiberty/open-liberty/pull/11378 and should be available in mpRestClient-3.0
         * and the latest version of Open Liberty (23.0.0.9).
         */
        System.out.println("SSLAffirmativeHostnameVerifier.verify() invoked");
        return true;
    }
}
