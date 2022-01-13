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

import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.TimeUnit;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.InputStreamEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class DataAssertITCase {
    private CloseableHttpClient client = HttpClientBuilder.create().build();
    private static final int MAX_RETRY_TIMES = 5;
    private String validationEntry;
    private String serviceEntry;
    private String healthCheckEntry;
    private String suffixEntry;
    
    @Before
    public void setup() throws IOException {
        serviceEntry = System.getProperty("service.entry");
        suffixEntry = System.getProperty("suffix.entry");
        validationEntry = System.getProperty("validation.entry");
        healthCheckEntry = System.getProperty("healthcheck.entry");
    }

    @Test(timeout = 180_000)
    public void verify() throws IOException, InterruptedException {
        int times = 0;

        do {
            TimeUnit.SECONDS.sleep(2L); // Wait Nginx Lua Agent available.

            try (CloseableHttpResponse response = client.execute(new HttpGet(healthCheckEntry))) {
                if (response.getStatusLine().getStatusCode() == 200) {
                    break;
                }
            }
        } while (++times <= MAX_RETRY_TIMES);

        try (CloseableHttpResponse response = client.execute(new HttpGet(serviceEntry))) {
            Assert.assertEquals(200, response.getStatusLine().getStatusCode());
        }

        try (CloseableHttpResponse response = client.execute(new HttpGet(suffixEntry))) {
            Assert.assertEquals(200, response.getStatusLine().getStatusCode());
        }

        times = 0;
        do {
            TimeUnit.SECONDS.sleep(5L); // Wait Agent reported TraceSegment.

            HttpPost post = new HttpPost(validationEntry);
            InputStream input = DataAssertITCase.class.getResourceAsStream("/expectedData.yaml");
            post.setEntity(new InputStreamEntity(input));
            try (CloseableHttpResponse response = client.execute(post)) {
                System.out.println(response.getStatusLine().getStatusCode());
                if (response.getStatusLine().getStatusCode() == 200) {
                    break;
                }
            }
            post.abort();
        }
        while (++times <= MAX_RETRY_TIMES);

        Assert.assertTrue("Test failed.", times <= MAX_RETRY_TIMES);
    }

    @After
    public void cleanup() throws IOException {
        client.close();
    }
}
