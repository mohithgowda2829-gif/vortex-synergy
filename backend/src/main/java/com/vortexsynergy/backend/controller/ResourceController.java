package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.resource.CreateResourceRequest;
import com.vortexsynergy.backend.dto.resource.ResourceResponse;
import com.vortexsynergy.backend.dto.common.ApiMessageResponse;
import com.vortexsynergy.backend.dto.common.PagedResponse;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.ResourceService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/resources")
@RequiredArgsConstructor
public class ResourceController {

    private final ResourceService resourceService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ResourceResponse create(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody CreateResourceRequest request
    ) {
        return resourceService.createResource(principal, request);
    }

    @PutMapping("/{id}")
    public ResourceResponse update(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID id,
        @Valid @RequestBody CreateResourceRequest request
    ) {
        return resourceService.updateResource(principal, id, request);
    }

    @PostMapping("/{id}/cancel")
    public ApiMessageResponse cancel(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID id
    ) {
        return resourceService.cancelResource(principal, id);
    }

    @GetMapping
    public PagedResponse<ResourceResponse> list(
        @RequestParam(required = false) ResourceType resourceType,
        @RequestParam(required = false, name = "query") String query,
        @RequestParam(required = false) String city,
        @RequestParam(required = false) String area,
        @RequestParam(required = false) Double latitude,
        @RequestParam(required = false) Double longitude,
        @RequestParam(defaultValue = "EXPIRY") String sort,
        @RequestParam(defaultValue = "0") Integer page,
        @RequestParam(required = false) Integer size,
        @RequestParam(required = false) Integer limit
    ) {
        return resourceService.getResources(
            resourceType,
            query,
            city,
            area,
            sort,
            latitude,
            longitude,
            page,
            size != null ? size : limit
        );
    }

    @GetMapping("/{id}")
    public ResourceResponse getById(@PathVariable UUID id, @AuthenticationPrincipal UserPrincipal principal) {
        return resourceService.getResource(id, principal);
    }

    @GetMapping("/mine")
    public List<ResourceResponse> mine(@AuthenticationPrincipal UserPrincipal principal) {
        return resourceService.getMyResources(principal);
    }
}
