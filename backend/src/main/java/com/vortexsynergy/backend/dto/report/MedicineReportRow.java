package com.vortexsynergy.backend.dto.report;

import com.vortexsynergy.backend.model.enums.MedicineAccessType;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import java.util.UUID;

public record MedicineReportRow(
    UUID resourceId,
    String title,
    String medicineName,
    String category,
    MedicineAccessType accessType,
    Boolean prescriptionRequired,
    VerificationStatus verificationStatus,
    String verificationNotes
) {
}
