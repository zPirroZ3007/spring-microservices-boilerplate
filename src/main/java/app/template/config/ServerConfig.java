package app.template.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.boot.web.servlet.server.ConfigurableServletWebServerFactory;

@Configuration
public class ServerConfig {

    @Value("${spring.application.name}")
    private String title;

    @Bean
    public WebServerFactoryCustomizer<ConfigurableServletWebServerFactory> webServerFactoryCustomizer() {
        var name = title.split("-")[1].toLowerCase();
        return factory -> factory.setContextPath("/api/" + name);
    }
}

