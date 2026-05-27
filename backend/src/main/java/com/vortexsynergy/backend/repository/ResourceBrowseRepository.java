package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.model.enums.ResourceType;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface ResourceBrowseRepository {

    Page<ResourceBrowseRow> searchPublicResources(ResourceBrowseQuery query, Pageable pageable);

    record ResourceBrowseQuery(
        ResourceType resourceType,
        String searchQuery,
        String city,
        String area,
        Double latitude,
        Double longitude,
        String sort
    ) {
    }

    record ResourceBrowseRow(UUID resourceId) {
    }
}
