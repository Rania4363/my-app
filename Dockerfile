FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY target/my-app-1.0-SNAPSHOT.jar app.jar

CMD ["java", "-jar", "app.jar"]
