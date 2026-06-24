package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.model.ChatMessage;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {

    List<ChatMessage> findByClaimIdOrderByCreatedAtAsc(UUID claimId);

    long countByRecipientIdAndReadAtIsNull(UUID recipientId);
}
