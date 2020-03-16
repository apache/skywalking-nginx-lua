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

package org.apache.skywalking.plugin.test.agent.tool.validator.assertor;

import org.apache.skywalking.plugin.test.agent.tool.validator.assertor.exception.SpanAssertFailedException;
import org.apache.skywalking.plugin.test.agent.tool.validator.entity.Segment;

public class SegmentPredictionFailedCause {
    private final Segment actualSegment;
    private final SpanAssertFailedException spanAssertFailedCause;

    public SegmentPredictionFailedCause(SpanAssertFailedException spanAssertFailedCause, Segment actualSegment) {
        this.spanAssertFailedCause = spanAssertFailedCause;
        this.actualSegment = actualSegment;
    }

    public Segment getActualSegment() {
        return actualSegment;
    }

    public SpanAssertFailedException getSpanAssertFailedCause() {
        return spanAssertFailedCause;
    }
}
