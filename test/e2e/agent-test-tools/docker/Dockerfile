FROM openjdk:8

WORKDIR /usr/local/skywalking-nginx-lua

COPY run.sh /
RUN chmod +x /run.sh

COPY skywalking-validator.jar ./agent-test-tools/skywalking-validator-tool.jar
COPY skywalking-mock-collector.tar.gz ./agent-test-tools/

RUN tar -xvf ./agent-test-tools/skywalking-mock-collector.tar.gz -C agent-test-tools/
RUN chmod +x /usr/local/skywalking-nginx-lua/agent-test-tools/skywalking-mock-collector/bin/collector-startup.sh

CMD ["/usr/local/skywalking-nginx-lua/agent-test-tools/skywalking-mock-collector/bin/collector-startup.sh"]
