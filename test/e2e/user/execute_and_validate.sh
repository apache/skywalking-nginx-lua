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
trigger() {
  url=$(pos=$1 yq '.entries.[env(pos)].url' ./scenario)
  method=$(pos=$1 yq '.entries.[env(pos)].method // "GET"' ./scenario)

  pos=$1 yq '.entries.[env(pos)].headers.[]' ./scenario > /req_header

  rst=$(curl -Is -X $method -H @/req_header $url | head -1 | grep "HTTP/1.1 200")
  if [[ -z "$rst" ]]; then
    echo "failed to access $2"
    exit 1
  fi
  echo "access $2 successful"
}

clear() {
  rst=$(curl -Is -X GET http://${COLLECTOR}/receiveData/clear | head -1 | grep "HTTP/1.1 200")
  if [[ -z "$rst" ]]; then
    echo "failed to clear collector segments"
    exit 1
  fi
  echo "sweep collector segments successful"
}

validate() {
  name=$1
  expectedData=$2

  times=0
  while [ $times -lt $MAX_RETRY_TIMES ]; do
    curl -X POST --data-raw "$(cat $expectedData)" --dump-header ./header -o /response -s ${COLLECTOR}/dataValidate
    rst=$(head -1 /header | grep "HTTP/1.1 200")
    if [[ -n "$rst" ]]; then
      echo "scenario $name verification successful"
      return 0
    fi

    sleep 3
    times=$((times+1))
  done

  cat /response
  echo "scenario $name verification failed"
  exit 1
}

scenarios=$(yq e '.scenarios | length' /config.yaml)
echo "total scenarios number: $scenarios"

scenario=0
while [ $scenario -lt $scenarios ]; do
  clear

  pos=$scenario yq -P '.scenarios.[env(pos)]' /config.yaml > ./scenario
  name=$(yq '.name' ./scenario)
  entries=$(yq '.entries | length' ./scenario)
  expectedData=$(yq '.expected' ./scenario)

  entry=0
  while [ $entry -lt $entries ]; do
    trigger $entry

    entry=$((entry+1))
  done

  sleep 5 # wait for agent report trace segments.
  validate $name $expectedData

  scenario=$((scenario+1))
done
