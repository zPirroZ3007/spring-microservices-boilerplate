FROM openjdk:17

WORKDIR /app
COPY ./build/libs/app.jar /app

ENV PROD=true

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]