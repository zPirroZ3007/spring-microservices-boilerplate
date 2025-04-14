package app.template;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.utility.DockerImageName;

import java.util.Arrays;

@SpringBootApplication
public class TemplateApplication {

    public static void main(String[] args) {
        SpringApplication springApp = new SpringApplication(TemplateApplication.class);

        if (System.getenv().containsKey("PROD"))
            springApp.setAdditionalProfiles("prod");

        if (Arrays.asList(args).contains("--spring.profiles.active=openapi")) {
            MySQLContainer<?> mysqlContainer = new MySQLContainer<>(DockerImageName.parse("mysql:latest"));

            mysqlContainer.start();

            System.setProperty("spring.datasource.url", mysqlContainer.getJdbcUrl());
            System.setProperty("spring.datasource.username", mysqlContainer.getUsername());
            System.setProperty("spring.datasource.password", mysqlContainer.getPassword());
        }

        springApp.run(args);
    }

    @Value("${spring.application.name}")
    private String title;

    @Bean
    public OpenAPI openAPI() {
        var name = title.split("-")[1].toLowerCase();

        return new OpenAPI().info(new Info().title(title).version("1.0.0"))
                .servers(Arrays.asList(new Server().url("https://my.app/api/" + name).description("production"),
                        new Server().url("http://localhost:8080/api/" + name).description("dev")));
    }

}
