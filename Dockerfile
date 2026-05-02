FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY target/*.jar app.jar

FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
COPY --from=builder /app/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
