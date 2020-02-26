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

package org.apache.skywalking.plugin.test.validator.validator.assertor;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonParser;
import java.io.File;
import java.io.FileWriter;
import java.nio.file.Files;
import java.util.List;
import org.apache.skywalking.plugin.test.agent.tool.validator.assertor.DataAssert;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.Data;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.DataForRead;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.RegistryItems;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.SegmentItem;
import org.junit.Test;
import org.yaml.snakeyaml.Yaml;

public class ExpectedDataVO {
    RegistryItems registryItems;
    List<SegmentItem> segmentItems;

    private static final Gson gson = new Gson();

    static interface type {
        String HEART_BEAT = "/v2/instance/heartbeat";
        String SEGMENTS = "/v2/segments";
        String INSTANCE_REGISTER = "/v2/instance/register";
        String SERVICE_REGISTER = "/v2/service/register";
    }

    @Test
    public void test() throws Exception {
        List<String> lines = Files.readAllLines(
            new File(ExpectedDataVO.class.getResource("/logs/trace.log").getFile()).toPath());

        final DataCollector collector = new DataCollector();
        lines.forEach(line -> {
            String[] pair = line.split(" ", 2);
            JsonElement element = new JsonParser().parse(pair[1].replaceAll("\\\\", ""));

            switch (pair[0]) {
                case type.HEART_BEAT:
                    break;
                case type.SERVICE_REGISTER: {
                    element.getAsJsonObject().get("services").getAsJsonArray().forEach(e -> {
                        collector.serviceRegistry(e.getAsJsonObject().get("serviceName").getAsString());
                    });
                    break;
                }
                case type.INSTANCE_REGISTER: {
                    JsonArray instances = element.getAsJsonObject().getAsJsonArray("instances");
                    instances.forEach(el -> {
                        collector.instanceRegistry(el.getAsJsonObject().get("serviceId").getAsInt());
                    });
                    break;
                }
                case type.SEGMENTS: {
                    collector.addSegmentItem(element);
                }
                default: {
                }
            }
        });
        Yaml yaml = new Yaml();
        System.out.println(yaml.dump(yaml.load(gson.toJson(collector.collect()))));
        DataAssert.assertEquals(
            Data.Loader.loadData(DataCollector.class.getResourceAsStream("/expectedData.yaml")),
            Data.Loader.loadData(DataCollector.class.getResourceAsStream("/actualData.yaml"))
//            yaml.loadAs(gson.toJson(collector.collect()), DataForRead.class)
        );
    }

}
