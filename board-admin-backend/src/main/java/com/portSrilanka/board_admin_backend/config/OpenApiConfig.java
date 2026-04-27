package com.portSrilanka.board_admin_backend.config;

import io.swagger.v3.oas.models.*;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.*;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Board Admin API")
                        .version("1.0")
                        .description("Backend API for board administration system"));
    }
}