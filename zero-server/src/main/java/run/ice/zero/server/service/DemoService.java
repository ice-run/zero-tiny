package run.ice.zero.server.service;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import run.ice.zero.server.model.demo.Cat;
import run.ice.zero.server.model.demo.Dog;
import tools.jackson.databind.ObjectMapper;

/**
 * @author DaoDao
 */
@Slf4j
@Service
public class DemoService {

    @Resource
    private ObjectMapper objectMapper;

    public Dog demo(Cat cat) {

        String name = cat.getName();
        name = new StringBuilder(name).reverse().toString();

        Dog dog = new Dog();
        dog.setName(name);

        String json = objectMapper.writeValueAsString(dog);
        log.info("DemoService: {}", json);

        return dog;
    }

}
