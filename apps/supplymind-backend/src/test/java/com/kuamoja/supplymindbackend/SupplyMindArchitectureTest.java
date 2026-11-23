package com.kuamoja.supplymindbackend;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

public class SupplyMindArchitectureTest {
    @Test
    void applicationModulesShouldRespectBoundaries(){
        ApplicationModules modules = ApplicationModules.of(SupplymindApplication.class);

        modules.verify();
    }
}
