#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

rst=$(curl -X POST -Is ${SERVICE_ENTRY} | head -1 | grep "HTTP/1.1 200")
if [[ -z "$rst" ]]; then
  echo "failed to access ${SERVICE_ENTRY}"
  exit 1
fi
echo "access ${SERVICE_ENTRY} success"

rst=$(curl -X GET -Is ${SUFFIX_ENTRY} | head -1 | grep "HTTP/1.1 200")
if [[ -z "$rst" ]]; then
  echo "failed to access ${SUFFIX_ENTRY}"
  exit 1
fi
echo "access ${SUFFIX_ENTRY} success"

sleep 5 # Wait Agent reported TraceSegment.

times=0
while [ $times -lt $MAX_RETRY_TIMES ]; do
  curl -X POST --data-raw "$(cat /expectedData.yaml)" --dump-header ./header -o /response -s ${VALIDATION_ENTRY}
  rst=$(head -1 /header | grep "HTTP/1.1 200")
  if [[ -n "$rst" ]]; then
    echo "Verification successful"
    exit 0
  fi

  sleep 3
  times=$((times+1))
done

cat /response
exit 1
