FROM maven:3.6-jdk-8-alpine

ARG ZEPPELIN_GIT_URL=https://github.com/apache/zeppelin.git
RUN git clone ${ZEPPELIN_GIT_URL} --depth=1

RUN cd zeppelin && ./dev/change_scala_version.sh 2.11

RUN cd zeppelin && mvn clean package -DskipTests -Phadoop-3.1 -Pscala-2.11
