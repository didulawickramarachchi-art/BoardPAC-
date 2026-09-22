package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.PackDelivery;
import com.portSrilanka.board_admin_backend.enums.DeliveryStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PackDeliveryRepository extends JpaRepository<PackDelivery, Long> {
    List<PackDelivery> findByPaperId(Long paperId);
    List<PackDelivery> findByUserId(Long userId);
    long countByUserIdAndDeliveryStatus(Long userId, DeliveryStatus deliveryStatus);
    Optional<PackDelivery> findByPaperIdAndUserId(Long paperId, Long userId);
}
