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
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.skywalking.plugin.test.agent.tool.validator.assertor.DataAssert;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.Data;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.DataForRead;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;
import org.yaml.snakeyaml.Yaml;

@RunWith(JUnit4.class)
public class DataAssertIT {
    private static Logger logger = LogManager.getLogger(DataAssertIT.class);
    Gson gson = new Gson();

    @Test
    public void testAssertFunction() throws InterruptedException, IOException {
        TimeUnit.SECONDS.sleep(2L);
        System.out.println(System.getProperty("ping.url"));
        URLConnection connection = new URL(System.getProperty("ping.url")).openConnection(); //
//            "http://localhost:" + System.getProperty("nginx.port") + "/ingress").openConnection();
        connection.connect();
        System.out.println(connection.getContent());
        TimeUnit.SECONDS.sleep(4L);

        while (true) {
            final DataCollector collector = new DataCollector();
            URL url = DataAssertIT.class.getResource("/logs/trace.log");
            List<String> lines = Files.readAllLines(new File(url.getFile()).toPath());
            logger.info("lines : {}", lines.size());

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
                    }
                    default: {
                    }
                }
            }

            Yaml yaml = new Yaml();
            try {
                if (!collector.hasSegments()) {
                    throw new NullPointerException();
                }

                System.out.println(yaml.dump(yaml.load(gson.toJson(collector.collect()))));
                DataAssert.assertEquals(
                    Data.Loader.loadData(DataCollector.class.getResourceAsStream("/expectedData.yaml")),
                    yaml.loadAs(gson.toJson(collector.collect()), DataForRead.class)
                );
                return;
            } catch (Exception e) {
                TimeUnit.SECONDS.sleep(2L);
                logger.error(e.getMessage(), e);
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