/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.skywalking.plugin.test.agent.tool.validator.entity;

import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
public class SegmentItemForRead implements SegmentItem {
    private String serviceName;
    private String segmentSize;
    private List<SegmentForRead> segments;

    @Override
    public String serviceName() {
        return serviceName;
    }

    @Override
    public String segmentSize() {
        return segmentSize;
    }

    @Override
    public List<Segment> segments() {
        if (segments == null) {
            return null;
        }
        return new ArrayList<>(segments);
    }

    @Override
    public String toString() {
        StringBuilder message = new StringBuilder(String.format("\nSegment Item[%s]", serviceName));
        message.append(String.format(" - segment size:\t\t%s\n", segmentSize));
        return message.toString();
    }
}
