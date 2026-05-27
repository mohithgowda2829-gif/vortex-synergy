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
            if (userRepository.count() > 0) {
                return;
            }

            User admin = userRepository.save(user("Admin Lead", "admin@vortex.local", "+10000000001", Role.ADMIN, true, true, true, true, passwordEncoder));
            User donor = userRepository.save(user("Asha Donor", "donor@vortex.local", "+10000000002", Role.DONOR, true, true, true, true, passwordEncoder));
            User receiver = userRepository.save(user("Ravi Receiver", "receiver@vortex.local", "+10000000003", Role.RECEIVER, true, true, true, true, passwordEncoder));
            User doctor = userRepository.save(user("Dr. Noor", "doctor@vortex.local", "+10000000005", Role.DOCTOR_PHARMACIST, true, true, true, true, passwordEncoder));

            createUserVerification(verificationRepository, donor, donor, VerificationType.EMAIL, VerificationStatus.APPROVED, "Seed email verified");
            createUserVerification(verificationRepository, donor, donor, VerificationType.PHONE, VerificationStatus.APPROVED, "Seed phone verified");
            createUserVerification(verificationRepository, receiver, receiver, VerificationType.EMAIL, VerificationStatus.APPROVED, "Seed email verified");
            createUserVerification(verificationRepository, receiver, receiver, VerificationType.PHONE, VerificationStatus.APPROVED, "Seed phone verified");
            createUserVerification(verificationRepository, doctor, admin, VerificationType.PROFESSIONAL_ACCOUNT, VerificationStatus.APPROVED, "Doctor approved by admin");
            createUserVerification(verificationRepository, donor, admin, VerificationType.MEDICINE_DONOR, VerificationStatus.APPROVED, "Medicine donor flow approved");

            Resource foodResource = resourceRepository.save(Resource.builder()
                .donor(donor)
                .resourceType(ResourceType.FOOD)
                .title("Fresh meal packs")
                .description("Cooked vegetarian meal packs for same-day distribution")
                .quantity(30)
                .availableQuantity(20)
                .unit("meals")
                .status(ResourceStatus.AVAILABLE)
                .city("Bengaluru")
                .area("Indiranagar")
                .latitude(12.9719)
                .longitude(77.6412)
                .locationNote("Community kitchen counter")
                .foodType("Vegetarian")
                .preparedTime(LocalDateTime.now().minusHours(1))
                .expiresAt(LocalDateTime.now().plusHours(3))
                .medicalVerificationStatus(VerificationStatus.APPROVED)
                .requiresReceiverDelivery(false)
                .build());

            Resource medicineResource = resourceRepository.save(Resource.builder()
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
                .build());

            Resource pendingMedicine = resourceRepository.save(Resource.builder()
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
                .build());

            verificationRepository.save(Verification.builder()
                .targetType(VerificationTargetType.RESOURCE)
                .targetId(medicineResource.getId())
                .verificationType(VerificationType.MEDICINE_LISTING)
                .status(VerificationStatus.APPROVED)
                .requestedBy(donor)
                .reviewedBy(doctor)
                .reviewedAt(Instant.now().minusSeconds(3600))
                .note("Approved seed medicine listing")
                .build());

            verificationRepository.save(Verification.builder()
                .targetType(VerificationTargetType.RESOURCE)
                .targetId(pendingMedicine.getId())
                .verificationType(VerificationType.MEDICINE_LISTING)
                .status(VerificationStatus.PENDING)
                .requestedBy(donor)
                .note("Pending doctor review")
                .build());

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
        };
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
