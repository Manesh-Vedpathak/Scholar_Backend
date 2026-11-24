# ==========================================
# BUILD STAGE
# ==========================================

FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .

COPY src ./src

# Retry Maven build if Maven Central temporarily
# responds with HTTP 429 or another network error.

RUN for attempt in 1 2 3 4 5; do \
      echo "Maven build attempt: $attempt"; \
      if mvn -B -ntp clean package -DskipTests; then \
        exit 0; \
      fi; \
      echo "Build failed. Waiting before retry..."; \
      sleep $((attempt * 30)); \
    done; \
    echo "Maven build failed after 5 attempts"; \
    exit 1


# ==========================================
# RUNTIME STAGE
# ==========================================

FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]