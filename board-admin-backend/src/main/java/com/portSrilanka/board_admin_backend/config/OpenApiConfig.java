package com.portSrilanka.board_admin_backend.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.*;

@Configuration
public class OpenApiConfig {

    private static final String JWT_SECURITY_SCHEME = "bearerAuth";

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .addServersItem(new Server()
                        .url("/")
                        .description("Default server"))
                .components(new Components()
                        .addSecuritySchemes(JWT_SECURITY_SCHEME, new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Paste the JWT access token from the login API.")))
                .addSecurityItem(new SecurityRequirement().addList(JWT_SECURITY_SCHEME))
                .info(new Info()
                        .title("Board Admin API")
                        .version("1.0")
                        .description("Backend API for board administration system"));
    }
}
