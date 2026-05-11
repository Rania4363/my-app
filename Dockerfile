FROM maven:3.9.6-eclipse-temurin-17 AS builder
 
WORKDIR /app
 
# Copier pom.xml en premier pour profiter du cache Docker
COPY pom.xml .
RUN mvn dependency:go-offline -q
 
# Copier le code source et builder
COPY src ./src
RUN mvn clean package -DskipTests
 
# ===========================
# Stage 2 : Image finale
# ===========================
FROM eclipse-temurin:17-jre-alpine
 
WORKDIR /app
 
# Créer un utilisateur non-root (bonne pratique sécurité)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
 
# Copier le JAR depuis le stage builder
COPY --from=builder /app/target/*.jar app.jar
 
# Changer le propriétaire
RUN chown appuser:appgroup app.jar
 
USER appuser
 
EXPOSE 8080
 
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -q --spider http://localhost:8080/actuator/health || exit 1
 
ENTRYPOINT ["java", "-jar", "app.jar"]
