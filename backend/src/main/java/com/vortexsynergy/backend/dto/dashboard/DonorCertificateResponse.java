package com.vortexsynergy.backend.dto.dashboard;

public record DonorCertificateResponse(
    String donorName,
    long numberOfContributions,
    long impactCount
) {
}
