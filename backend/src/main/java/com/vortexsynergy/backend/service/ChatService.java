package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.chat.ChatMessageRequest;
import com.vortexsynergy.backend.dto.chat.ChatMessageResponse;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.ChatMessage;
import com.vortexsynergy.backend.model.Claim;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.NotificationType;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.repository.ChatMessageRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;
    private final ClaimService claimService;
    private final NotificationService notificationService;
    private final AuditService auditService;

    @Transactional
    public List<ChatMessageResponse> conversation(UserPrincipal principal, UUID claimId) {
        User actor = currentUser(principal);
        Claim claim = claimService.findClaim(claimId);
        ensureParticipant(actor, claim);
        List<ChatMessage> messages = chatMessageRepository.findByClaimIdOrderByCreatedAtAsc(claimId);
        boolean dirty = false;
        for (ChatMessage message : messages) {
            if (message.getRecipient().getId().equals(actor.getId()) && message.getReadAt() == null) {
                message.setReadAt(Instant.now());
                dirty = true;
            }
        }
        if (dirty) {
            chatMessageRepository.saveAll(messages);
        }
        return messages.stream().map(ChatMessageResponse::from).toList();
    }

    @Transactional
    public ChatMessageResponse send(UserPrincipal principal, ChatMessageRequest request) {
        User sender = currentUser(principal);
        Claim claim = claimService.findClaim(request.claimId());
        ensureParticipant(sender, claim);
        User recipient = resolveRecipient(sender, claim);

        ChatMessage message = chatMessageRepository.save(ChatMessage.builder()
            .claim(claim)
            .sender(sender)
            .recipient(recipient)
            .message(request.message().trim())
            .build());

        notificationService.notifyUser(
            recipient,
            NotificationType.CHAT_MESSAGE,
            "New chat message",
            sender.getFullName() + ": " + request.message().trim()
        );
        auditService.log(sender, "CHAT_MESSAGE_SENT", "CLAIM", claim.getId().toString(), "Chat message sent");
        return ChatMessageResponse.from(message);
    }

    private User resolveRecipient(User sender, Claim claim) {
        if (sender.getRole() == Role.ADMIN) {
            return claim.getReceiver();
        }
        if (claim.getReceiver().getId().equals(sender.getId())) {
            return claim.getResource().getDonor();
        }
        return claim.getReceiver();
    }

    private void ensureParticipant(User actor, Claim claim) {
        boolean allowed = actor.getRole() == Role.ADMIN
            || claim.getReceiver().getId().equals(actor.getId())
            || claim.getResource().getDonor().getId().equals(actor.getId());
        if (!allowed) {
            throw new ForbiddenException("You are not part of this claim conversation");
        }
    }

    private User currentUser(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
    }
}
