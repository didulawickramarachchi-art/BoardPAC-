package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.PackDelivery;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PackDeliveryRepository extends JpaRepository<PackDelivery, Long> {
    List<PackDelivery> findByPaperId(Long paperId);
    List<PackDelivery> findByUserId(Long userId);
    Optional<PackDelivery> findByPaperIdAndUserId(Long paperId, Long userId);
}
