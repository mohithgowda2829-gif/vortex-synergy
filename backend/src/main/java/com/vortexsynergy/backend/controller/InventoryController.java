package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.inventory.InventoryAdjustRequest;
import com.vortexsynergy.backend.dto.inventory.InventoryItemResponse;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.InventoryService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    @GetMapping("/my")
    public List<InventoryItemResponse> mine(@AuthenticationPrincipal UserPrincipal principal) {
        return inventoryService.mine(principal);
    }

    @PostMapping("/consume")
    public InventoryItemResponse consume(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody InventoryAdjustRequest request
    ) {
        return inventoryService.consume(principal, request);
    }

    @PatchMapping("/storage")
    public InventoryItemResponse updateStorage(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody InventoryAdjustRequest request
    ) {
        return inventoryService.updateStorage(principal, request);
    }
}
