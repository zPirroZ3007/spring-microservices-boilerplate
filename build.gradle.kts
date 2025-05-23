import java.nio.file.Files
import java.nio.file.Paths

plugins {
    java
    id("org.springframework.boot") version "3.5.0"
    id("org.springdoc.openapi-gradle-plugin") version "1.8.0"
    id("io.spring.dependency-management") version "1.1.4"
    id("org.openapi.generator") version "7.5.0"
}

group = "app"
version = "0.0.1-SNAPSHOT"

java {
    sourceCompatibility = JavaVersion.VERSION_17
}

tasks.getByName<org.springframework.boot.gradle.tasks.bundling.BootJar>("bootJar") {
    this.archiveFileName.set("app.jar")
}

configurations {
    compileOnly {
        extendsFrom(configurations.annotationProcessor.get())
    }
}

repositories {
    mavenCentral()
}

extra["sentryVersion"] = "7.3.0"

dependencies {
    annotationProcessor("org.springframework.boot:spring-boot-configuration-processor")
    annotationProcessor("org.projectlombok:lombok")

    developmentOnly("org.springframework.boot:spring-boot-devtools")

    if (System.getenv("BUILD_NUMBER") == null) {
        developmentOnly("org.springframework.boot:spring-boot-docker-compose")
    }

    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-jdbc")
    implementation("org.springframework.boot:spring-boot-starter-jooq")
    implementation("io.sentry:sentry-spring-boot-starter-jakarta")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("com.amazonaws.secretsmanager:aws-secretsmanager-jdbc:2.0.2")
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.4.0")

    compileOnly("org.projectlombok:lombok")
    runtimeOnly("com.mysql:mysql-connector-j")

    implementation("org.springframework.boot:spring-boot-testcontainers")
    implementation("org.testcontainers:junit-jupiter")
    implementation("org.testcontainers:mysql")

    testImplementation("io.rest-assured:rest-assured:5.4.0")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

ext {
    set("springCloudVersion", "2023.0.0")
}

openApi {
    waitTimeInSeconds.set(180)
    apiDocsUrl.set("http://localhost:8080/api/${rootProject.name.split("-")[1]}/v3/api-docs")
    outputDir.set(file("$projectDir/src/main/resources"))
    customBootRun {
        args.set(listOf("--spring.profiles.active=openapi", "--title=${rootProject.name} openapi"))
    }
}

openApiGenerate {
    val trimmedName = rootProject.name.replace("app-", "").replace("-service", "")
    generatorName.set("java")
    version.set("1.0-SNAPSHOT")
    groupId.set("app")
    id.set(rootProject.name.replace("app-", ""))
    inputSpec.set("$projectDir/src/main/resources/openapi.json")
    outputDir.set("$buildDir/client")
    apiPackage.set("app.$trimmedName")
    modelPackage.set("app.$trimmedName.model")
    configOptions.set(
        mapOf(
            "dateLibrary" to "java8"
        )
    )
}

tasks {
    forkedSpringBootRun {
        args.add("--spring.profiles.active=openapi")
        doNotTrackState("See https://github.com/springdoc/springdoc-openapi-gradle-plugin/issues/102")
        environment("SPRING_PROFILES_ACTIVE", "openapi")
    }
}
dependencyManagement {
    imports {
        mavenBom("io.sentry:sentry-bom:${property("sentryVersion")}")
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.register("updateApplicationYaml") {
    val yamlFile = file("src/main/resources/application.yml")

    doLast {
        if (!yamlFile.exists()) {
            println("⚠️ File application.yml non trovato. Creazione di un nuovo file...")
            yamlFile.writeText("spring:\n  application:\n    name: ${project.name}\n")
            return@doLast
        }

        val yamlPath = Paths.get(yamlFile.absolutePath)
        val yamlLines = Files.readAllLines(yamlPath).toMutableList()

        var springIndex: Int? = null
        var appIndex: Int? = null
        var nameIndex: Int? = null

        for (i in yamlLines.indices) {
            val line = yamlLines[i].trim()

            if (line.startsWith("spring:")) {
                springIndex = i
            } else if (springIndex != null && line.startsWith("application:")) {
                appIndex = i
            } else if (appIndex != null && line.startsWith("name:")) {
                nameIndex = i
                break
            }
        }

        if (nameIndex != null) {
            val currentName = yamlLines[nameIndex].split(":")[1].trim()
            if (currentName == project.name) {
                return@doLast
            }

            yamlLines[nameIndex] = "    name: ${project.name}"
        } else if (appIndex != null) {
            yamlLines.add(appIndex + 1, "    name: ${project.name}")
        } else if (springIndex != null) {
            yamlLines.add(springIndex + 1, "  application:")
            yamlLines.add(springIndex + 2, "    name: ${project.name}")
        } else {
            yamlLines.add("\nspring:")
            yamlLines.add("  application:")
            yamlLines.add("    name: ${project.name}")
        }

        Files.write(yamlPath, yamlLines)
    }
}

tasks.named("processResources") {
    dependsOn("updateApplicationYaml")
}

tasks.withType<JavaExec>().configureEach {
    systemProperty("spring.application.name", project.name)
}

fun getPropOrEnv(prop: String, env: String): String? {
    return if (project.hasProperty(prop)) project.property(prop) as String? else System.getenv(env);
}

tasks.withType<JavaExec> {
    systemProperty("title", "${rootProject.name} openapi")
}