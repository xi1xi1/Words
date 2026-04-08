# beileme（背了么）— Spring Boot 3 + Java 17
FROM eclipse-temurin:17-jre-alpine

RUN apk add --no-cache wget

WORKDIR /app

COPY target/beileme-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

  ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
