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

package org.apache.skywalking.plugin.test.validator.assertor;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.apache.skywalking.plugin.test.validator.assertor.entity.ExpectedDataEntity;
import org.apache.skywalking.plugin.test.validator.assertor.entity.RegistryItemsEntity;

@Slf4j
public class DataCollector {
    // For SegmentItems
    private Map<String, List<JsonObject>> serviceAndSegments = Maps.newHashMap();

    // For RegistryItems
    private final Map<String, Integer> instanceMap = Maps.newHashMap();
    private final Map<Integer, String> serviceMap = Maps.newHashMap();
    private Map<String, List<String>> serviceAndOperations = Maps.newHashMap();
    private int serviceIdGenerator = 0;

    public DataCollector serviceRegistry(String serviceName) {
        if (!serviceMap.containsValue(serviceName)) {
            serviceMap.put(++serviceIdGenerator, serviceName);
        }
        return this;
    }

    public DataCollector instanceRegistry(int serviceId) {
        String serviceName = serviceMap.get(serviceId);
        instanceMap.put(serviceName, instanceMap.getOrDefault(serviceName, 0) + 1);
        return this;
    }

    public DataCollector addSegmentItem(JsonElement element) {
        final JsonElement spans = element.getAsJsonObject().get("spans");
        if (spans.getAsJsonArray().size() == 0) {
            return this;
        }

        try {
            JsonObject segment = new JsonObject();
            segment.addProperty("segmentId", "1.159.00000000000000000");
            segment.add("spans", spans);

            final int serviceId = element.getAsJsonObject().get("serviceId").getAsInt();
            final String serviceName = serviceMap.get(serviceId);

            spans.getAsJsonArray().forEach(span -> {
                JsonObject jsonObject = span.getAsJsonObject();

                // extract operation name
                List<String> operations = serviceAndOperations.getOrDefault(serviceName, Lists.newArrayList());
                operations.add(jsonObject.get("operationName").getAsString());
                serviceAndOperations.put(serviceName, operations);

                // remove unless properties
                JsonElement refs = jsonObject.get("refs");
                if (refs != null) {
                    if (refs.isJsonObject()) {
                        jsonObject.remove("refs");
                    } else {
                        refs.getAsJsonArray().forEach(el -> {
                            el.getAsJsonObject().addProperty("parentTraceSegmentId", "parentTraceSegmentId");
                        });
                    }
                }
                JsonElement logs = jsonObject.get("logs");
                if (logs != null) {
                    if (logs.isJsonObject()) {
                        jsonObject.remove("logs");
                    }
                }
                JsonElement tags = jsonObject.get("tags");
                if (tags != null) {
                    if (tags.isJsonObject()) {
                        jsonObject.remove("tags");
                    }
                }
            });

            List<JsonObject> segments = serviceAndSegments.getOrDefault(serviceName, Lists.newArrayList());
            segments.add(segment);

            serviceAndSegments.put(serviceName, segments);
        } catch (Exception e) {
            log.error(element.toString(), e);
        }
        return this;
    }

    public boolean hasSegments() {
        return !serviceAndOperations.isEmpty();
    }

    public ExpectedDataEntity collect() {
        RegistryItemsEntity registryItems = new RegistryItemsEntity();
        registryItems.setInstances(getInstances());
        registryItems.setApplications(getApplications());
        registryItems.setOperationNames(getOperationNames());

        ExpectedDataEntity entity = new ExpectedDataEntity();
        entity.setRegistryItems(registryItems);
        entity.setSegmentItems(getSegmentItems());
        return entity;
    }

    private List<JsonObject> getSegmentItems() {
        return serviceAndSegments.entrySet().stream().map(e -> {
            JsonObject item = new JsonObject();
            item.addProperty("serviceName", e.getKey());
            item.addProperty("segmentSize", e.getValue().size());

            List<JsonObject> values = e.getValue();
            JsonArray elements = new JsonArray();
            values.forEach(elements::add);
            item.add("segments", elements);
            return item;
        }).collect(Collectors.toList());
    }

    private List<Map<String, List<String>>> getOperationNames() {
        return serviceAndOperations.entrySet().stream().map(e -> {
            Map<String, List<String>> instance = Maps.newHashMap();
            instance.put(e.getKey(), e.getValue());
            return instance;
        }).collect(Collectors.toList());
    }

    private List<Map<String, Integer>> getInstances() {
        return instanceMap.entrySet().stream().map(entry -> {
            Map<String, Integer> instance = Maps.newHashMap();
            instance.put(entry.getKey(), entry.getValue());
            return instance;
        }).collect(Collectors.toList());
    }

    private List<Map<String, Integer>> getApplications() {
        return serviceMap.entrySet().stream().map(entry -> {
            Map<String, Integer> instance = Maps.newHashMap();
            instance.put(entry.getValue(), entry.getKey() + 1);
            return instance;
        }).collect(Collectors.toList());
    }
}
