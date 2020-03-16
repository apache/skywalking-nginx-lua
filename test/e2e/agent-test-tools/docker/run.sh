#!/bin/bash

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

# The variable names in UPPERCASE ltter represent that they are injected from outside.

base_home="$(cd "$(dirname $0)"; pwd)"

function exitOnError() {
    echo -e "\033[31m[ERROR] $1\033[0m">&2
    exitAndClean 1
}

function healthCheck() {
    HEALTH_CHECK_URL=$1

    STATUS_CODE="-1"
    TIMES=${TIMES:-150}
    for ((i=1; i<=${TIMES}; i++));
    do
        STATUS_CODE="$(curl --max-time 3 -Is ${HEALTH_CHECK_URL} | head -n 1)"
        if [[ $STATUS_CODE == *"200"* ]]; then
          echo "${HEALTH_CHECK_URL}: ${STATUS_CODE}"
          return 0
        fi
        sleep 2
    done

    exitOnError "$2 url=${HEALTH_CHECK_URL}, status=${STATUS_CODE} health check failed!"
}

if [[ -z "${TESTCASE_STARTUP_SCRIPT}" ]]; then
    exitOnError "The name of startup script cannot be empty!"
fi

tools_home=/usr/local/skywalking-nginx-lua/agent-test-tools
testcase_home=/usr/local/skywalking-nginx-lua/testcase

echo "To start mock collector"
${tools_home}/skywalking-mock-collector/bin/collector-startup.sh 1>/dev/null &
healthCheck http://localhost:12800/receiveData

healthCheck http://localhost:12800/status

echo "To visit entry service"
curl -s --max-time 3 ${TESTCASE_SERVICE_ENTRY}
sleep 5

echo "To receive actual data"
curl -s --max-time 3 http://localhost:12800/receiveData > ${testcase_home}/data/actualData.yaml
[[ ! -f ${testcase_home}/data/actualData.yaml ]] && exitOnError "${TESTCASE_NAME}, 'actualData.yaml' Not Found!"

echo "To validate"
java -jar \
    -Xmx256m -Xms256m \
    -DcaseName="${TESTCASE_NAME}" \
    -DtestCasePath=${testcase_home}/data/ \
    ${tools_home}/skywalking-validator-tool.jar 1>/dev/null
status=$?

if [[ $status -eq 0 ]]; then
  echo "Scenario[${TESTCASE_NAME}] passed!" >&2
else
  cat ${testcase_home}/data/actualData.yaml >&2
  exitOnError "Scenario[${TESTCASE_NAME}] failed!"
fi
exitAndClean $status
