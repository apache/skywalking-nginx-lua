/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

package org.apache.skywalking.e2e;

import com.google.common.collect.Lists;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.concurrent.TimeUnit;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.InputStreamEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.message.BasicNameValuePair;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class DataAssertITCase {
    private CloseableHttpClient client = HttpClientBuilder.create().build();
    private static final int MAX_RETRY_TIMES = 5;
    private String collectorBaseURL;
    private String serviceEntry;
    private String collectorInBaseURL;

    private String kongAdminBaseUrl;

    @Before
    public void setup() throws IOException {
        serviceEntry = System.getProperty("service.entry");
        collectorBaseURL = System.getProperty("collector.baseURL");
        collectorInBaseURL = System.getProperty("collector.in.baseURL");

        kongAdminBaseUrl = System.getProperty("kong.admin.baseURL");
        try (CloseableHttpResponse response = client.execute(new HttpGet(kongAdminBaseUrl))) {
            Assert.assertEquals(200, response.getStatusLine().getStatusCode());
        }
        createService();
        addRouteForService();
        enablePlugin();
    }

    @Test(timeout = 180_000)
    public void verify() throws IOException, InterruptedException {
        int times = 0;

        do {
            TimeUnit.SECONDS.sleep(2L); // Wait Nginx Lua Agent available.

            try (CloseableHttpResponse response = client.execute(new HttpGet(collectorBaseURL + "/status"))) {
                if (response.getStatusLine().getStatusCode() == 200) {
                    break;
                }
            }
        }
        while (++times <= MAX_RETRY_TIMES);

        TimeUnit.SECONDS.sleep(3L);
        try (CloseableHttpResponse response = client.execute(new HttpGet(serviceEntry))) {
            final int statusCode = response.getStatusLine().getStatusCode();
            Assert.assertTrue(statusCode >= 200 && statusCode <= 400);
        }

        times = 0;
        do {
            TimeUnit.SECONDS.sleep(5L); // Wait Agent reported TraceSegment.

            HttpPost post = new HttpPost(collectorBaseURL + "/dataValidate");
            InputStream input = DataAssertITCase.class.getResourceAsStream("/expectedData.yaml");
            post.setEntity(new InputStreamEntity(input));
            try (CloseableHttpResponse response = client.execute(post)) {
                if (response.getStatusLine().getStatusCode() == 200) {
                    break;
                }
            }
            post.abort();
        }
        while (++times <= MAX_RETRY_TIMES);

        Assert.assertTrue("Test failed.", times <= MAX_RETRY_TIMES);
    }

    private void createService() throws IOException {
        HttpPost post = new HttpPost(kongAdminBaseUrl + "/services");
        List<BasicNameValuePair> basicNameValuePairs = Lists.newArrayList(
            new BasicNameValuePair("name", "example-service"),
            new BasicNameValuePair("url", "http://mockbin.org")
        );
        UrlEncodedFormEntity entity = new UrlEncodedFormEntity(basicNameValuePairs);
        post.setEntity(entity);
        try (CloseableHttpResponse response = client.execute(post)) {
            Assert.assertEquals(201, response.getStatusLine().getStatusCode());
        }
    }

    private void addRouteForService() throws IOException {
        HttpPost post = new HttpPost(kongAdminBaseUrl + "/services/example-service/routes");
        List<BasicNameValuePair> basicNameValuePairs = Lists.newArrayList(
            new BasicNameValuePair("name", "mocking"),
            new BasicNameValuePair("paths[]", "/mock")
        );
        UrlEncodedFormEntity entity = new UrlEncodedFormEntity(basicNameValuePairs);
        post.setEntity(entity);
        try (CloseableHttpResponse response = client.execute(post)) {
            Assert.assertEquals(201, response.getStatusLine().getStatusCode());
        }
    }

    private void enablePlugin() throws IOException {
        HttpPost post = new HttpPost(kongAdminBaseUrl + "/plugins");
        List<BasicNameValuePair> basicNameValuePairs = Lists.newArrayList(
            new BasicNameValuePair("name", "skywalking"),
            new BasicNameValuePair("config.backend_http_uri", collectorInBaseURL),
            new BasicNameValuePair("config.service_name", "kong"),
            new BasicNameValuePair("config.service_instance_name", "kong-with-skywalking"),
            new BasicNameValuePair("config.sample_ratio", "100")
        );
        UrlEncodedFormEntity entity = new UrlEncodedFormEntity(basicNameValuePairs);
        post.setEntity(entity);
        try (CloseableHttpResponse response = client.execute(post)) {
            Assert.assertEquals(201, response.getStatusLine().getStatusCode());
        }
    }

    @After
    public void cleanup() throws IOException {
        client.close();
    }
}
