/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package org.apache.skywalking.plugin.test.validator.validator.assertor;

import com.google.common.io.ByteStreams;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonParser;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.net.URLConnection;
import java.nio.file.Files;
import java.util.List;
import java.util.concurrent.TimeUnit;
import lombok.extern.slf4j.Slf4j;
import org.apache.skywalking.plugin.test.agent.tool.validator.assertor.DataAssert;
import org.apache.skywalking.plugin.test.agent.tool.validator.assertor.exception.TypeUndefinedException;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.Data;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.DataForRead;
import org.junit.Test;
import org.yaml.snakeyaml.Yaml;

@Slf4j
public class DataAssertITCase {
    private static final Gson gson = new Gson();

    @Test
    public void testAssertFunction() throws InterruptedException, IOException, TypeUndefinedException {
        TimeUnit.SECONDS.sleep(10L); // wait for agent registry

        URLConnection connection = new URL(System.getProperty("ping.url")).openConnection();
        connection.connect();
        log.info("Http Response: {}", new String(ByteStreams.toByteArray(connection.getInputStream())));

        TimeUnit.SECONDS.sleep(6L);

        for (int times = 0; times < 30; times++) { // retry 30 times, that will spend 60s in the worst case.
            final DataCollector collector = new DataCollector();
            URL url = DataAssertIT.class.getResource("/logs/trace.log");
            List<String> lines = Files.readAllLines(new File(url.getFile()).toPath());
            log.info("lines : {}", lines.size());

            for (int i = 0; i < lines.size() - 1; i++) {
                String[] pair = lines.get(i).split(" ", 2);

                JsonElement element = new JsonParser().parse(pair[1].replaceAll("\\\\", "").trim());
                switch (pair[0]) {
                    case Type.HEART_BEAT:
                        break;
                    case Type.SERVICE_REGISTER: {
                        element.getAsJsonObject().get("services").getAsJsonArray().forEach(e -> {
                            collector.serviceRegistry(e.getAsJsonObject().get("serviceName").getAsString());
                        });
                        break;
                    }
                    case Type.INSTANCE_REGISTER: {
                        JsonArray instances = element.getAsJsonObject().getAsJsonArray("instances");
                        instances.forEach(el -> {
                            collector.instanceRegistry(el.getAsJsonObject().get("serviceId").getAsInt());
                        });
                        break;
                    }
                    case Type.SEGMENTS: {
                        collector.addSegmentItem(element);
                        break;
                    }
                    default: {
                        throw new TypeUndefinedException("Type " + pair[0] + " undefined.");
                    }
                }
            }

            try {
                if (!collector.hasSegments()) {
                    throw new NullPointerException();
                }

                DataAssert.assertEquals(
                    Data.Loader.loadData(DataCollector.class.getResourceAsStream("/expectedData.yaml")),
                    Data.Loader.loadData(gson.toJson(collector.collect()))
                );
                return;
            } catch (Exception e) {
                TimeUnit.SECONDS.sleep(2L);
                log.error(e.getMessage(), e);
            }
        }
    }

    static interface Type {
        String HEART_BEAT = "/v2/instance/heartbeat";
        String SEGMENTS = "/v2/segments";
        String INSTANCE_REGISTER = "/v2/instance/register";
        String SERVICE_REGISTER = "/v2/service/register";
    }

}