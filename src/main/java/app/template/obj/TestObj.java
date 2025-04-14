package app.template.obj;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@Table(name = "test")
public class TestObj {

    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    @Id
    private Long id;

    @Column(name = "name", nullable = false)
    private String name;

    public TestObj(String name) {
        this.name = name;
    }
}
