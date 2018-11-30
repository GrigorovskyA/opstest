FROM openjdk:8-jdk
WORKDIR /opt
COPY . /opt/
RUN ./mvnw package -DforkCount=0

FROM openjdk:8-jre-alpine
WORKDIR /opt
COPY --from=0 /opt/target/suchapp-0.0.1-SNAPSHOT.jar /opt/
CMD ["java", "-jar", "/opt/suchapp-0.0.1-SNAPSHOT.jar"]
EXPOSE 8080
