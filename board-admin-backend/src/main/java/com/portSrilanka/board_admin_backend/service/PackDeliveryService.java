package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.report.PackDeliveryResponse;
import com.portSrilanka.board_admin_backend.entity.PackDelivery;
import com.portSrilanka.board_admin_backend.repository.PackDeliveryRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import com.portSrilanka.board_admin_backend.enums.DeliveryStatus;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import org.springframework.security.access.AccessDeniedException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PackDeliveryService {

    private final PackDeliveryRepository packDeliveryRepository;
    private final UserRepository userRepository;
    private final PaperRepository paperRepository;
    private final AuditService auditService;

    public List<PackDeliveryResponse> getByPaper(Long paperId) {
        return packDeliveryRepository.findByPaperId(paperId).stream()
                .map(this::map)
                .toList();
    }

    public List<PackDeliveryResponse> getByUser(Long userId, String username, boolean secretary) {
        var current = userRepository.findByUsername(username).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (!secretary && !current.getId().equals(userId)) throw new AccessDeniedException("Delivery history access denied");
        return packDeliveryRepository.findByUserId(userId).stream()
                .map(this::map)
                .toList();
    }

    public void markDownloaded(Long paperId, String username) {
        var user = userRepository.findByUsername(username).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        var paper = paperRepository.findById(paperId).orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        var delivery = packDeliveryRepository.findByPaperIdAndUserId(paperId, user.getId())
                .orElse(PackDelivery.builder().paper(paper).user(user).deliveryStatus(DeliveryStatus.NOT_READ).build());
        if (delivery.getDeliveryStatus() != DeliveryStatus.READ) delivery.setDeliveryStatus(DeliveryStatus.DOWNLOADED);
        packDeliveryRepository.save(delivery);
        auditService.logInfo("PACK_DELIVERY", "DOWNLOAD_OFFLINE", username, "Paper " + paperId + " downloaded", "DEVICE");
    }

    private PackDeliveryResponse map(PackDelivery pd) {
        return PackDeliveryResponse.builder()
                .paperId(pd.getPaper().getId())
                .paperTitle(pd.getPaper().getTitle())
                .userId(pd.getUser().getId())
                .username(pd.getUser().getUsername())
                .deliveryStatus(pd.getDeliveryStatus())
                .build();
    }
}
