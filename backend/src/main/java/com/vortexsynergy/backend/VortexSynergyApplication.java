package com.vortexsynergy.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class VortexSynergyApplication {

    public static void main(String[] args) {
        SpringApplication.run(VortexSynergyApplication.class, args);
    }
}
