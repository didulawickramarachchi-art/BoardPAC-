package com.portSrilanka.board_admin_backend.dto.report;

import com.portSrilanka.board_admin_backend.enums.DeliveryStatus;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PackDeliveryResponse {
    private Long paperId;
    private String paperTitle;
    private Long userId;
    private String username;
    private DeliveryStatus deliveryStatus;
}
