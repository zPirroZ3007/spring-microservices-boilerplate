package app.template;

import app.template.obj.TestObj;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.utility.DockerImageName;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(classes = TemplateApplication.class)
public class TemplateApplicationTests {

    static MySQLContainer<?> mysqlContainer = new MySQLContainer<>(DockerImageName.parse("mysql:latest"));

    @Autowired
    private TestRepository testRepository;

    @BeforeAll
    public static void setUp() {
        mysqlContainer.start();
    }

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysqlContainer::getJdbcUrl);
        registry.add("spring.datasource.username", mysqlContainer::getUsername);
        registry.add("spring.datasource.password", mysqlContainer::getPassword);
    }

    @Test
    public void contextLoads() {
    }

    @Test
    public void testDatabase() {
        testRepository.save(new TestObj("test"));

        assertEquals(testRepository.findAll().size(), 1);
    }

}
