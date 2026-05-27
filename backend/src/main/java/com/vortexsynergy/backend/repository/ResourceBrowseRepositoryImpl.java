package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.repository.ResourceBrowseRepository.ResourceBrowseQuery;
import com.vortexsynergy.backend.repository.ResourceBrowseRepository.ResourceBrowseRow;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class ResourceBrowseRepositoryImpl implements ResourceBrowseRepository {

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Override
    public Page<ResourceBrowseRow> searchPublicResources(ResourceBrowseQuery query, Pageable pageable) {
        MapSqlParameterSource parameters = new MapSqlParameterSource();
        String baseSql = buildBaseSql(query, parameters);

        Long total = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) " + baseSql,
            parameters,
            Long.class
        );

        parameters.addValue("limit", pageable.getPageSize());
        parameters.addValue("offset", pageable.getOffset());

        List<ResourceBrowseRow> rows = jdbcTemplate.query(
            "SELECT r.id " + baseSql + buildOrderByClause(query, parameters) + " LIMIT :limit OFFSET :offset",
            parameters,
            (resultSet, rowNumber) -> new ResourceBrowseRow(resultSet.getObject("id", java.util.UUID.class))
        );

        return new PageImpl<>(rows, pageable, total == null ? 0 : total);
    }

    private String buildBaseSql(ResourceBrowseQuery query, MapSqlParameterSource parameters) {
        StringBuilder sql = new StringBuilder(
            """
            FROM resources r
            JOIN users u ON u.id = r.donor_id
            WHERE r.status NOT IN ('CANCELLED', 'EXPIRED', 'CLAIMED')
              AND r.available_quantity > 0
              AND (
                    (
                        r.resource_type = 'FOOD'
                        AND u.account_verified = TRUE
                        AND r.expires_at IS NOT NULL
                        AND r.expires_at > CURRENT_TIMESTAMP
                    )
                    OR
                    (
                        r.resource_type = 'MEDICINE'
                        AND r.medical_verification_status = 'APPROVED'
                        AND r.medicine_seal_status = 'SEALED'
                        AND r.medicine_expiry_date IS NOT NULL
                        AND r.medicine_expiry_date >= CURRENT_DATE
                        AND EXISTS (
                            SELECT 1
                            FROM verifications v
                            WHERE v.target_type = 'USER'
                              AND v.target_id = u.id
                              AND v.verification_type = 'MEDICINE_DONOR'
                              AND v.status = 'APPROVED'
                        )
                    )
                )
            """
        );

        if (query.resourceType() != null) {
            sql.append(" AND r.resource_type = :resourceType");
            parameters.addValue("resourceType", query.resourceType().name());
        }
        if (query.searchQuery() != null && !query.searchQuery().isBlank()) {
            sql.append(
                """
                 AND (
                    LOWER(r.title) LIKE :queryLike
                    OR LOWER(COALESCE(r.medicine_name, '')) LIKE :queryLike
                    OR LOWER(COALESCE(r.food_type, '')) LIKE :queryLike
                 )
                """
            );
            parameters.addValue("queryLike", "%" + query.searchQuery().trim().toLowerCase() + "%");
        }
        if (query.city() != null && !query.city().isBlank()) {
            sql.append(" AND (LOWER(r.city) LIKE :cityLike OR LOWER(r.city) LIKE :cityAliasLike)");
            parameters.addValue("cityLike", "%" + query.city().trim().toLowerCase() + "%");
            parameters.addValue("cityAliasLike", "%" + cityAlias(query.city()) + "%");
        }
        if (query.area() != null && !query.area().isBlank()) {
            sql.append(" AND LOWER(r.area) LIKE :areaLike");
            parameters.addValue("areaLike", "%" + query.area().trim().toLowerCase() + "%");
        }

        return sql.toString();
    }

    private String cityAlias(String value) {
        String normalized = value.trim().toLowerCase();
        if (normalized.contains("bengaluru")) {
            return normalized.replace("bengaluru", "bangalore");
        }
        if (normalized.contains("bangalore")) {
            return normalized.replace("bangalore", "bengaluru");
        }
        return normalized;
    }

    private String buildOrderByClause(ResourceBrowseQuery query, MapSqlParameterSource parameters) {
        String sort = query.sort() == null ? "EXPIRY" : query.sort().trim().toUpperCase();
        return switch (sort) {
            case "LOCATION" -> " ORDER BY LOWER(r.city) ASC, LOWER(r.area) ASC, r.created_at ASC";
            case "PRIORITY" -> """
                ORDER BY (
                    CASE
                        WHEN r.resource_type = 'FOOD' AND r.expires_at < CURRENT_TIMESTAMP + INTERVAL '2 hours' THEN 90
                        WHEN r.resource_type = 'FOOD' AND r.expires_at < CURRENT_TIMESTAMP + INTERVAL '6 hours' THEN 60
                        WHEN r.resource_type = 'MEDICINE' AND r.medicine_expiry_date <= CURRENT_DATE + INTERVAL '7 days' THEN 70
                        WHEN r.resource_type = 'MEDICINE' AND r.medicine_expiry_date <= CURRENT_DATE + INTERVAL '30 days' THEN 40
                        ELSE 0
                    END
                    +
                    CASE
                        WHEN r.medical_verification_status = 'APPROVED' THEN 5
                        ELSE 0
                    END
                ) DESC,
                COALESCE(r.expires_at, r.medicine_expiry_date::timestamp) ASC NULLS LAST,
                r.created_at ASC
                """;
            case "NEAREST" -> {
                parameters.addValue("latitude", query.latitude());
                parameters.addValue("longitude", query.longitude());
                yield """
                    ORDER BY
                    (POWER(r.latitude - :latitude, 2) + POWER(r.longitude - :longitude, 2)) ASC NULLS LAST,
                    COALESCE(r.expires_at, r.medicine_expiry_date::timestamp) ASC NULLS LAST,
                    r.created_at ASC
                    """;
            }
            default -> """
                ORDER BY COALESCE(r.expires_at, r.medicine_expiry_date::timestamp) ASC NULLS LAST, r.created_at ASC
                """;
        };
    }
}
