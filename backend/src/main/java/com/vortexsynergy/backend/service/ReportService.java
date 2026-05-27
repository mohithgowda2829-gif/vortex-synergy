package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.report.ClaimReportRow;
import com.vortexsynergy.backend.dto.report.DeliveryReportRow;
import com.vortexsynergy.backend.dto.report.DonationReportRow;
import com.vortexsynergy.backend.dto.report.ExpiryReportRow;
import com.vortexsynergy.backend.dto.report.MedicineReportRow;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.repository.ClaimRepository;
import com.vortexsynergy.backend.repository.DeliveryRepository;
import com.vortexsynergy.backend.repository.ResourceRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.repository.VerificationRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReportService {

    private final ResourceRepository resourceRepository;
    private final ClaimRepository claimRepository;
    private final DeliveryRepository deliveryRepository;
    private final VerificationRepository verificationRepository;
    private final UserRepository userRepository;

    public String donationsCsv(UserPrincipal principal) {
        User actor = currentUser(principal);
        List<DonationReportRow> rows = actor.getRole() == Role.ADMIN
            ? resourceRepository.findDonationReportRowsForAdmin()
            : claimRepository.findDonationReportRowsForReceiver(actor.getId());

        StringBuilder csv = header("resource_id,title,type,donor,status,city,area,quantity,available,created_at");
        for (DonationReportRow row : rows) {
            row(csv,
                row.resourceId(),
                row.title(),
                row.type(),
                row.donor(),
                row.status(),
                row.city(),
                row.area(),
                row.quantity(),
                row.available(),
                row.createdAt());
        }
        return csv.toString();
    }

    public String claimsCsv(UserPrincipal principal) {
        User actor = currentUser(principal);
        List<ClaimReportRow> rows = actor.getRole() == Role.ADMIN
            ? claimRepository.findClaimReportRowsForAdmin()
            : claimRepository.findClaimReportRowsForReceiver(actor.getId());

        StringBuilder csv = header("claim_id,resource_title,receiver,status,quantity,delivery_requested,priority_score,priority_explanation,created_at");
        for (ClaimReportRow row : rows) {
            row(csv,
                row.claimId(),
                row.resourceTitle(),
                row.receiver(),
                row.status(),
                row.quantity(),
                row.deliveryRequested(),
                row.priorityScore(),
                row.priorityExplanation(),
                row.createdAt());
        }
        return csv.toString();
    }

    public String expiryCsv(UserPrincipal principal) {
        ensureReportingAccess(principal);
        List<ExpiryReportRow> rows = resourceRepository.findExpiryReportRows();

        StringBuilder csv = header("resource_id,title,type,status,city,area,expires_at_or_date");
        for (ExpiryReportRow row : rows) {
            row(csv,
                row.resourceId(),
                row.title(),
                row.type(),
                row.status(),
                row.city(),
                row.area(),
                row.type() == com.vortexsynergy.backend.model.enums.ResourceType.FOOD ? row.expiresAt() : row.medicineExpiryDate());
        }
        return csv.toString();
    }

    public String medicineCsv(UserPrincipal principal) {
        ensureReportingAccess(principal);
        List<MedicineReportRow> rows = resourceRepository.findMedicineReportRows();

        StringBuilder csv = header("resource_id,title,medicine_name,category,access_type,prescription_required,verification_status,verification_notes");
        for (MedicineReportRow row : rows) {
            row(csv,
                row.resourceId(),
                row.title(),
                row.medicineName(),
                row.category() != null ? row.category() : "UNSPECIFIED",
                row.accessType() != null ? row.accessType() : "UNSPECIFIED",
                row.prescriptionRequired() != null ? row.prescriptionRequired() : "NOT_SET",
                row.verificationStatus(),
                row.verificationNotes());
        }
        return csv.toString();
    }

    public String deliveryCsv(UserPrincipal principal) {
        User actor = currentUser(principal);
        List<DeliveryReportRow> rows = actor.getRole() == Role.ADMIN
            ? deliveryRepository.findDeliveryReportRowsForAdmin()
            : deliveryRepository.findDeliveryReportRowsForReceiver(actor.getId());

        StringBuilder csv = header("delivery_id,claim_id,resource_title,receiver,order_number,agent_name,agent_mobile,vehicle_number,status,pickup_approved_at,delivered_at,failed_reason");
        for (DeliveryReportRow row : rows) {
            row(csv,
                row.deliveryId(),
                row.claimId(),
                row.resourceTitle(),
                row.receiver(),
                row.orderNumber(),
                row.agentName(),
                row.agentMobile(),
                row.vehicleNumber(),
                row.status(),
                row.pickupApprovedAt(),
                row.deliveredAt(),
                row.failedReason());
        }
        return csv.toString();
    }

    private void ensureReportingAccess(UserPrincipal principal) {
        User actor = currentUser(principal);
        if (actor.getRole() != Role.ADMIN && actor.getRole() != Role.RECEIVER) {
            throw new ForbiddenException("Reports are available only to admins and receiver organizations");
        }
    }

    private User currentUser(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
            .orElseThrow(() -> new ForbiddenException("User not found"));
    }

    private StringBuilder header(String headerLine) {
        return new StringBuilder(headerLine).append('\n');
    }

    private void row(StringBuilder csv, Object... values) {
        for (int i = 0; i < values.length; i++) {
            if (i > 0) {
                csv.append(',');
            }
            csv.append(escape(values[i]));
        }
        csv.append('\n');
    }

    private String escape(Object value) {
        if (value == null) {
            return "";
        }
        String text = value.toString().replace("\"", "\"\"");
        return "\"" + text + "\"";
    }
}
