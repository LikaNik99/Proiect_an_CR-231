FROM container-registry.oracle.com/java/openjdk:latest
WORKDIR /app
COPY RoyalBlackjackServer.jar app.jar
COPY *.txt ./
EXPOSE 5000
CMD ["java", "-jar", "app.jar"]