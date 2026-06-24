package com.vortexsynergy.backend.config;

import com.vortexsynergy.backend.model.Claim;
import com.vortexsynergy.backend.model.Delivery;
import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.ClaimStatus;
import com.vortexsynergy.backend.model.enums.DeliveryStatus;
import com.vortexsynergy.backend.model.enums.MedicineSealStatus;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationTargetType;
import com.vortexsynergy.backend.model.enums.VerificationType;
import com.vortexsynergy.backend.repository.ClaimRepository;
import com.vortexsynergy.backend.repository.DeliveryRepository;
import com.vortexsynergy.backend.repository.ResourceRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.repository.VerificationRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class SeedDataConfig {

    @Bean
    CommandLineRunner seedData(
        UserRepository userRepository,
        ResourceRepository resourceRepository,
        ClaimRepository claimRepository,
        DeliveryRepository deliveryRepository,
        VerificationRepository verificationRepository,
        PasswordEncoder passwordEncoder
    ) {
        return args -> {
            User admin = ensureUser(
                userRepository,
                "Admin Lead",
                "admin@vortex.local",
                "+10000000001",
                Role.ADMIN,
                passwordEncoder
            );
            User donor = ensureUser(
                userRepository,
                "Asha Donor",
                "donor@vortex.local",
                "+10000000002",
                Role.DONOR,
                passwordEncoder
            );
            User receiver = ensureUser(
                userRepository,
                "Ravi Receiver",
                "receiver@vortex.local",
                "+10000000003",
                Role.RECEIVER,
                passwordEncoder
            );
            User doctor = ensureUser(
                userRepository,
                "Dr. Noor",
                "doctor@vortex.local",
                "+10000000005",
                Role.DOCTOR_PHARMACIST,
                passwordEncoder
            );

            ensureVerification(verificationRepository, donor, donor, VerificationType.EMAIL, VerificationStatus.APPROVED, "Seed email verified");
            ensureVerification(verificationRepository, donor, donor, VerificationType.PHONE, VerificationStatus.APPROVED, "Seed phone verified");
            ensureVerification(verificationRepository, receiver, receiver, VerificationType.EMAIL, VerificationStatus.APPROVED, "Seed email verified");
            ensureVerification(verificationRepository, receiver, receiver, VerificationType.PHONE, VerificationStatus.APPROVED, "Seed phone verified");
            ensureVerification(verificationRepository, doctor, admin, VerificationType.PROFESSIONAL_ACCOUNT, VerificationStatus.APPROVED, "Doctor approved by admin");
            ensureVerification(verificationRepository, donor, admin, VerificationType.MEDICINE_DONOR, VerificationStatus.APPROVED, "Medicine donor flow approved");

            Resource foodResource = ensureResource(
                resourceRepository,
                "Fresh meal packs",
                Resource.builder()
                    .donor(donor)
                    .resourceType(ResourceType.FOOD)
                    .title("Fresh meal packs")
                    .description("Cooked vegetarian meal packs for same-day distribution")
                    .quantity(30)
                    .availableQuantity(30)
                    .unit("meals")
                    .status(ResourceStatus.AVAILABLE)
                    .city("Bengaluru")
                    .area("Indiranagar")
                    .latitude(12.9719)
                    .longitude(77.6412)
                    .locationNote("Community kitchen counter")
                    .foodType("Vegetarian")
                    .preparedTime(LocalDateTime.now().minusHours(1))
                    .expiresAt(LocalDateTime.now().plusDays(2))
                    .medicalVerificationStatus(VerificationStatus.APPROVED)
                    .requiresReceiverDelivery(false)
                    .build()
            );

            ensureResource(
                resourceRepository,
                "Ready rice meal bowls",
                Resource.builder()
                    .donor(donor)
                    .resourceType(ResourceType.FOOD)
                    .title("Ready rice meal bowls")
                    .description("Freshly packed rice bowls ready for immediate pickup")
                    .quantity(20)
                    .availableQuantity(20)
                    .unit("boxes")
                    .status(ResourceStatus.AVAILABLE)
                    .city("Bengaluru")
                    .area("Malleshwaram")
                    .latitude(13.0035)
                    .longitude(77.5706)
                    .locationNote("Temple kitchen service desk")
                    .foodType("Mixed meal")
                    .preparedTime(LocalDateTime.now().minusHours(2))
                    .expiresAt(LocalDateTime.now().plusDays(2).plusHours(2))
                    .medicalVerificationStatus(VerificationStatus.APPROVED)
                    .requiresReceiverDelivery(false)
                    .build()
            );

            Resource medicineResource = ensureResource(
                resourceRepository,
                "Sealed first aid kits",
                Resource.builder()
                    .donor(donor)
                    .resourceType(ResourceType.MEDICINE)
                    .title("Sealed first aid kits")
                    .description("Basic first aid kits with bandages and antiseptic")
                    .quantity(12)
                    .availableQuantity(12)
                    .unit("kits")
                    .status(ResourceStatus.AVAILABLE)
                    .city("Bengaluru")
                    .area("Koramangala")
                    .latitude(12.9352)
                    .longitude(77.6245)
                    .locationNote("Clinic pickup desk")
                    .medicineName("First Aid Kit")
                    .medicineExpiryDate(LocalDate.now().plusMonths(10))
                    .medicineSealStatus(MedicineSealStatus.SEALED)
                    .batchNumber("KIT-2026-01")
                    .medicineCategory("FIRST_AID")
                    .prescriptionRequired(false)
                    .medicalVerificationStatus(VerificationStatus.APPROVED)
                    .medicalVerifiedBy(doctor)
                    .medicalVerifiedAt(Instant.now().minusSeconds(3600))
                    .medicalVerificationNote("Sealed and fit for use")
                    .verificationNotes("Sealed and fit for use")
                    .requiresReceiverDelivery(false)
                    .build()
            );

            Resource pendingMedicine = ensureResource(
                resourceRepository,
                "Cough syrup packs",
                Resource.builder()
                    .donor(donor)
                    .resourceType(ResourceType.MEDICINE)
                    .title("Cough syrup packs")
                    .description("Sealed bottles awaiting review")
                    .quantity(8)
                    .availableQuantity(8)
                    .unit("bottles")
                    .status(ResourceStatus.AVAILABLE)
                    .city("Bengaluru")
                    .area("Whitefield")
                    .latitude(12.9698)
                    .longitude(77.7499)
                    .locationNote("Partner pharmacy back office")
                    .medicineName("Cough Syrup")
                    .medicineExpiryDate(LocalDate.now().plusMonths(4))
                    .medicineSealStatus(MedicineSealStatus.SEALED)
                    .batchNumber("MED-2045-A")
                    .medicineCategory("RESPIRATORY")
                    .prescriptionRequired(false)
                    .medicalVerificationStatus(VerificationStatus.PENDING)
                    .requiresReceiverDelivery(false)
                    .build()
            );

            ensureResource(
                resourceRepository,
                "Children vitamin syrup",
                Resource.builder()
                    .donor(donor)
                    .resourceType(ResourceType.MEDICINE)
                    .title("Children vitamin syrup")
                    .description("Vitamin syrup shipment pending doctor approval")
                    .quantity(6)
                    .availableQuantity(6)
                    .unit("bottles")
                    .status(ResourceStatus.AVAILABLE)
                    .city("Bengaluru")
                    .area("Jayanagar")
                    .latitude(12.9297)
                    .longitude(77.5938)
                    .locationNote("Pediatric support center desk")
                    .medicineName("Vitamin Syrup")
                    .medicineExpiryDate(LocalDate.now().plusMonths(7))
                    .medicineSealStatus(MedicineSealStatus.SEALED)
                    .batchNumber("VIT-2026-07")
                    .medicineCategory("SUPPLEMENTS")
                    .prescriptionRequired(false)
                    .medicalVerificationStatus(VerificationStatus.PENDING)
                    .requiresReceiverDelivery(false)
                    .build()
            );

            ensureVerification(
                verificationRepository,
                donor,
                doctor,
                medicineResource.getId(),
                VerificationType.MEDICINE_LISTING,
                VerificationStatus.APPROVED,
                "Approved seed medicine listing"
            );
            ensureVerification(
                verificationRepository,
                donor,
                null,
                pendingMedicine.getId(),
                VerificationType.MEDICINE_LISTING,
                VerificationStatus.PENDING,
                "Pending doctor review"
            );

            if (claimRepository.count() == 0) {
                Claim completedClaim = claimRepository.save(Claim.builder()
                    .resource(foodResource)
                    .receiver(receiver)
                    .quantity(10)
                    .status(ClaimStatus.CLAIMED)
                    .pickupCode("VTX-DEMO")
                    .reservedAt(Instant.now().minusSeconds(7200))
                    .reservationExpiresAt(Instant.now().plusSeconds(7200))
                    .confirmedAt(Instant.now().minusSeconds(5400))
                    .claimedAt(Instant.now().minusSeconds(1800))
                    .deliveryRequested(true)
                    .priorityScore(15)
                    .priorityExplanation("high-expiry resource, light fairness adjustment")
                    .pickupPersonName("Ravi Kumar")
                    .pickupPersonPhone("+919845612345")
                    .pickupVehicleNumber("KA-01-AB-4321")
                    .pickupVehicleDetails("White mini-van for NGO pickup")
                    .pickupDetailsSubmittedAt(Instant.now().minusSeconds(4800))
                    .pickupDetailsApproved(true)
                    .pickupDetailsApprovedAt(Instant.now().minusSeconds(4200))
                    .pickupConfirmedByReceiver(true)
                    .handoverConfirmed(true)
                    .build());

                deliveryRepository.save(Delivery.builder()
                    .claim(completedClaim)
                    .receiver(receiver)
                    .orderNumber("ORD-SEED-001")
                    .vehicleNumber("KA-01-AB-4321")
                    .agentName("Ravi Kumar")
                    .agentMobile("+919845612345")
                    .pickupApprovedAt(Instant.now().minusSeconds(3600))
                    .status(DeliveryStatus.DELIVERED)
                    .deliveredAt(Instant.now().minusSeconds(1800))
                    .lastLatitude(12.9719)
                    .lastLongitude(77.6412)
                    .lastLocationUpdateAt(Instant.now().minusSeconds(1800))
                    .notes("Seed delivery completed successfully")
                    .build());
            }
        };
    }

    private User ensureUser(
        UserRepository userRepository,
        String fullName,
        String email,
        String phone,
        Role role,
        PasswordEncoder passwordEncoder
    ) {
        return userRepository.findByEmailIgnoreCase(email)
            .map(existing -> {
                existing.setFullName(fullName);
                existing.setPhone(phone);
                existing.setRole(role);
                existing.setAccountVerified(true);
                existing.setEmailVerified(true);
                existing.setPhoneVerified(true);
                existing.setAdminApproved(true);
                existing.setActive(true);
                return userRepository.save(existing);
            })
            .orElseGet(() -> userRepository.save(user(fullName, email, phone, role, true, true, true, true, passwordEncoder)));
    }

    private Resource ensureResource(
        ResourceRepository resourceRepository,
        String title,
        Resource resource
    ) {
        return resourceRepository.findAll().stream()
            .filter(existing -> existing.getTitle().equalsIgnoreCase(title))
            .findFirst()
            .map(existing -> {
                existing.setDonor(resource.getDonor());
                existing.setResourceType(resource.getResourceType());
                existing.setTitle(resource.getTitle());
                existing.setDescription(resource.getDescription());
                existing.setQuantity(resource.getQuantity());
                existing.setAvailableQuantity(resource.getAvailableQuantity());
                existing.setUnit(resource.getUnit());
                existing.setStatus(resource.getStatus());
                existing.setCity(resource.getCity());
                existing.setArea(resource.getArea());
                existing.setLatitude(resource.getLatitude());
                existing.setLongitude(resource.getLongitude());
                existing.setLocationNote(resource.getLocationNote());
                existing.setFoodType(resource.getFoodType());
                existing.setPreparedTime(resource.getPreparedTime());
                existing.setExpiresAt(resource.getExpiresAt());
                existing.setMedicineName(resource.getMedicineName());
                existing.setMedicineExpiryDate(resource.getMedicineExpiryDate());
                existing.setMedicineSealStatus(resource.getMedicineSealStatus());
                existing.setBatchNumber(resource.getBatchNumber());
                existing.setMedicineCategory(resource.getMedicineCategory());
                existing.setMedicineAccessType(resource.getMedicineAccessType());
                existing.setPrescriptionRequired(resource.getPrescriptionRequired());
                existing.setMedicalVerificationStatus(resource.getMedicalVerificationStatus());
                existing.setMedicalVerifiedBy(resource.getMedicalVerifiedBy());
                existing.setMedicalVerifiedAt(resource.getMedicalVerifiedAt());
                existing.setMedicalVerificationNote(resource.getMedicalVerificationNote());
                existing.setVerificationNotes(resource.getVerificationNotes());
                existing.setRequiresReceiverDelivery(resource.isRequiresReceiverDelivery());
                existing.setPhotoUrls(resource.getPhotoUrls());
                return resourceRepository.save(existing);
            })
            .orElseGet(() -> resourceRepository.save(resource));
    }

    private void ensureVerification(
        VerificationRepository verificationRepository,
        User targetUser,
        User reviewer,
        VerificationType type,
        VerificationStatus status,
        String note
    ) {
        boolean exists = verificationRepository.findByTargetTypeAndTargetId(VerificationTargetType.USER, targetUser.getId()).stream()
            .anyMatch(verification -> verification.getVerificationType() == type && verification.getStatus() == status);
        if (!exists) {
            createUserVerification(verificationRepository, targetUser, reviewer == null ? targetUser : reviewer, type, status, note);
        }
    }

    private void ensureVerification(
        VerificationRepository verificationRepository,
        User donor,
        User reviewer,
        java.util.UUID targetId,
        VerificationType type,
        VerificationStatus status,
        String note
    ) {
        boolean exists = verificationRepository.findByTargetTypeAndTargetId(VerificationTargetType.RESOURCE, targetId).stream()
            .anyMatch(verification -> verification.getVerificationType() == type && verification.getStatus() == status);
        if (!exists) {
            verificationRepository.save(Verification.builder()
                .targetType(VerificationTargetType.RESOURCE)
                .targetId(targetId)
                .verificationType(type)
                .status(status)
                .requestedBy(donor)
                .reviewedBy(reviewer)
                .reviewedAt(reviewer == null ? null : Instant.now().minusSeconds(3600))
                .note(note)
                .build());
        }
    }

    private User user(
        String fullName,
        String email,
        String phone,
        Role role,
        boolean accountVerified,
        boolean emailVerified,
        boolean phoneVerified,
        boolean adminApproved,
        PasswordEncoder passwordEncoder
    ) {
        return User.builder()
            .fullName(fullName)
            .email(email)
            .phone(phone)
            .passwordHash(passwordEncoder.encode("Password123!"))
            .role(role)
            .accountVerified(accountVerified)
            .emailVerified(emailVerified)
            .phoneVerified(phoneVerified)
            .adminApproved(adminApproved)
            .active(true)
            .build();
    }

    private void createUserVerification(
        VerificationRepository verificationRepository,
        User targetUser,
        User reviewer,
        VerificationType type,
        VerificationStatus status,
        String note
    ) {
        verificationRepository.save(Verification.builder()
            .targetType(VerificationTargetType.USER)
            .targetId(targetUser.getId())
            .verificationType(type)
            .status(status)
            .requestedBy(targetUser)
            .reviewedBy(reviewer)
            .reviewedAt(Instant.now().minusSeconds(300))
            .note(note)
            .build());
    }
}
