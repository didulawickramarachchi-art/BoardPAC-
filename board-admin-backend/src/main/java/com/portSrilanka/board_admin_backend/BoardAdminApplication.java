package com.portSrilanka.board_admin_backend;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class BoardAdminApplication {
    public static void main(String[] args) {
        SpringApplication.run(BoardAdminApplication.class, args);
    }
}
