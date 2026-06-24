package com.vortexsynergy.backend.dto.chat;

import com.vortexsynergy.backend.model.ChatMessage;
import java.time.Instant;
import java.util.UUID;

public record ChatMessageResponse(
    UUID id,
    UUID claimId,
    UUID senderId,
    String senderName,
    UUID recipientId,
    String recipientName,
    String message,
    Instant createdAt,
    Instant readAt
) {
    public static ChatMessageResponse from(ChatMessage message) {
        return new ChatMessageResponse(
            message.getId(),
            message.getClaim().getId(),
            message.getSender().getId(),
            message.getSender().getFullName(),
            message.getRecipient().getId(),
            message.getRecipient().getFullName(),
            message.getMessage(),
            message.getCreatedAt(),
            message.getReadAt()
        );
    }
}
