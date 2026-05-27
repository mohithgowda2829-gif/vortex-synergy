package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.Role;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmailIgnoreCase(String email);

    Optional<User> findByPhone(String phone);

    long countByRole(Role role);

    List<User> findByRoleAndAdminApprovedFalse(Role role);
}
