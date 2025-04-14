package app.template;

import app.template.obj.TestObj;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface TestRepository extends CrudRepository<TestObj, Long>{

    List<TestObj> findAll();

}
