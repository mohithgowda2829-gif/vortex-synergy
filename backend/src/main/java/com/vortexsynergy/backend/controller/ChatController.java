package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.chat.ChatMessageRequest;
import com.vortexsynergy.backend.dto.chat.ChatMessageResponse;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.ChatService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @GetMapping("/{claimId}")
    public List<ChatMessageResponse> conversation(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID claimId
    ) {
        return chatService.conversation(principal, claimId);
    }

    @PostMapping
    public ChatMessageResponse send(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody ChatMessageRequest request
    ) {
        return chatService.send(principal, request);
    }
}
