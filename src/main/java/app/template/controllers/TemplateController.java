package app.template.controllers;

import app.template.obj.TestObj;
import app.template.TestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Nullable;
import java.util.List;

@RestController
@RequiredArgsConstructor
public class TemplateController {

    private final TestRepository testRepository;

    @GetMapping("/hello")
    public String hello() {
        return "Hello, World!";
    }

    @GetMapping("/test")
    public ResponseEntity<List<TestObj>> test(@Nullable String test) {
        if (test != null)
            testRepository.save(new TestObj(test));

        return ResponseEntity.ok(testRepository.findAll());
    }

}
