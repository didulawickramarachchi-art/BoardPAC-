package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.report.PackDeliveryResponse;
import com.portSrilanka.board_admin_backend.entity.PackDelivery;
import com.portSrilanka.board_admin_backend.repository.PackDeliveryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PackDeliveryService {

    private final PackDeliveryRepository packDeliveryRepository;

    public List<PackDeliveryResponse> getByPaper(Long paperId) {
        return packDeliveryRepository.findByPaperId(paperId).stream()
                .map(this::map)
                .toList();
    }

    public List<PackDeliveryResponse> getByUser(Long userId) {
        return packDeliveryRepository.findByUserId(userId).stream()
                .map(this::map)
                .toList();
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
