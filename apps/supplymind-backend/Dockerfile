FROM eclipse-temurin:27-jre

WORKDIR /app

COPY target/*.jar app.jar

USER 10001:10001

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
