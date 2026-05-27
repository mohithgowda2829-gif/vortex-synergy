package com.vortexsynergy.backend.dto.resource;

public record MedicalVerificationRequest(
    String note,
    String verificationNotes
) {
}
