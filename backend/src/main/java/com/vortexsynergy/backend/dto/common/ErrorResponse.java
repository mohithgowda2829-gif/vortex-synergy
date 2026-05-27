package com.vortexsynergy.backend.dto.common;

import java.time.Instant;
import java.util.Map;

public record ErrorResponse(
    Instant timestamp,
    int status,
    String message,
    Map<String, String> fieldErrors
) {
}
