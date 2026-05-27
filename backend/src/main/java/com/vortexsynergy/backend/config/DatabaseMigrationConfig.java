package com.vortexsynergy.backend.config;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DatabaseMigrationConfig implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        // Legacy V1/V2 volunteer accounts are retired in V3. Promote them to
        // receiver organizations so they keep access to delivery coordination.
        jdbcTemplate.update(
            """
            UPDATE users
            SET role = 'RECEIVER'
            WHERE role = 'VOLUNTEER'
            """
        );

        // Hibernate updates columns, but it will not widen old PostgreSQL enum-like
        // check constraints created from V1 entity definitions.
        jdbcTemplate.execute(
            """
            ALTER TABLE IF EXISTS deliveries
            DROP CONSTRAINT IF EXISTS deliveries_status_check
            """
        );
        jdbcTemplate.execute(
            """
            ALTER TABLE IF EXISTS deliveries
            ADD CONSTRAINT deliveries_status_check
            CHECK (
                status IN (
                    'OPEN',
                    'ACCEPTED',
                    'ASSIGNED',
                    'PICKUP_PENDING',
                    'PICKUP_APPROVED',
                    'IN_TRANSIT',
                    'DELIVERED',
                    'FAILED',
                    'CANCELLED'
                )
            )
            """
        );

        jdbcTemplate.execute(
            """
            ALTER TABLE IF EXISTS users
            DROP CONSTRAINT IF EXISTS users_role_check
            """
        );
        jdbcTemplate.execute(
            """
            ALTER TABLE IF EXISTS users
            ADD CONSTRAINT users_role_check
            CHECK (
                role IN (
                    'DONOR',
                    'RECEIVER',
                    'DOCTOR_PHARMACIST',
                    'ADMIN'
                )
            )
            """
        );
    }
}
