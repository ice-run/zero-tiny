package run.ice.zero.server.controller;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import run.ice.zero.server.ZeroServerApplicationTest;
import run.ice.zero.server.helper.TokenHelper;
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.demo.Cat;
import run.ice.zero.server.model.demo.Dog;
import tools.jackson.core.type.TypeReference;

@Slf4j
class DemoControllerTest extends ZeroServerApplicationTest {

    @Resource
    private TokenHelper tokenHelper;

    @Test
    void demo() {
        String api = "demo";

        String token = tokenHelper.createToken("admin");
        HttpHeaders headers = new HttpHeaders();
        headers.add(HttpHeaders.AUTHORIZATION, "Bearer " + token);

        Cat param = new Cat();
        param.setName("喵喵喵");
        Request<?> request = new Request<>(param);

        Response<Dog> response = mockMvc(api, headers, request, new TypeReference<>() {
        });

        Assertions.assertNotNull(response);
        Assertions.assertTrue(response.isOk());

        Dog data = response.getData();

        Assertions.assertNotNull(data);
        Assertions.assertNotNull(data.getName());
    }

}