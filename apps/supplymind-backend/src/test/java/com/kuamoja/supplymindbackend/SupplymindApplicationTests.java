package com.kuamoja.supplymindbackend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Testcontainers
class SupplyMindApplicationTests {

    @Container
    static final PostgreSQLContainer postgres =
        new PostgreSQLContainer("postgres:19.0")
            .withDatabaseName("supplymind_test")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureDatabase(DynamicPropertyRegistry registry) {
        registry.add(
            "spring.datasource.url",
            postgres::getJdbcUrl
        );
        registry.add(
            "spring.datasource.username",
            postgres::getUsername
        );
        registry.add(
            "spring.datasource.password",
            postgres::getPassword
        );
    }

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void applicationContextShouldStart() {
        assertThat(jdbc).isNotNull();
    }

    @Test
    void flywayShouldCreateInventoryTable() {
        Integer count = jdbc.queryForObject(
            """
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema = 'inventory'
              AND table_name = 'inventory_stock'
            """,
            Integer.class
        );

        assertThat(count).isEqualTo(1);
    }

    @Test
    void flywayShouldRecordSuccessfulMigration() {
        Boolean success = jdbc.queryForObject(
            """
            SELECT success
            FROM flyway.flyway_schema_history
            WHERE version = '001'
            """,
            Boolean.class
        );

        assertThat(success).isTrue();
    }

    @Test
    void shouldPersistValidInventoryStock() {
        UUID id = UUID.randomUUID();

        jdbc.update(
            """
            INSERT INTO inventory.inventory_stock
                (id, sku, on_hand_quantity, reserved_quantity)
            VALUES (?, ?, ?, ?)
            """,
            id,
            "TEST-VALID-" + id,
            6,
            2
        );

        Integer available = jdbc.queryForObject(
            """
            SELECT on_hand_quantity - reserved_quantity
            FROM inventory.inventory_stock
            WHERE id = ?
            """,
            Integer.class,
            id
        );

        assertThat(available).isEqualTo(4);
    }

    @Test
    void shouldRejectReservationAbovePhysicalStock() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(() ->
            jdbc.update(
                """
                INSERT INTO inventory.inventory_stock
                    (id, sku, on_hand_quantity,
                     reserved_quantity)
                VALUES (?, ?, ?, ?)
                """,
                id,
                "TEST-OVER-" + id,
                6,
                10
            )
        ).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void shouldRejectNegativeStock() {
        UUID id = UUID.randomUUID();

        assertThatThrownBy(() ->
            jdbc.update(
                """
                INSERT INTO inventory.inventory_stock
                    (id, sku, on_hand_quantity,
                     reserved_quantity)
                VALUES (?, ?, ?, ?)
                """,
                id,
                "TEST-NEG-" + id,
                -1,
                0
            )
        ).isInstanceOf(DataIntegrityViolationException.class);
    }
}
