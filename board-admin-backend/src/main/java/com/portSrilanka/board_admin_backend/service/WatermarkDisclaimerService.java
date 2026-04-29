package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.Paper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class WatermarkDisclaimerService {

    private final WorkflowSettingService workflowSettingService;

    public String getWatermarkType() {
        return workflowSettingService.getValue("WATERMARK_TYPE", "NONE");
    }

    public String buildDisclaimerMessage(Paper paper) {
        String global = workflowSettingService.getValue(
                "DISCLAIMER_MESSAGE_WHEN_EMAILING_OR_PRINTING_AGENDA_ITEM",
                ""
        );

        if (paper.getDisclaimerMessage() != null && !paper.getDisclaimerMessage().isBlank()) {
            return paper.getDisclaimerMessage();
        }

        return global;
    }

    public boolean canPrintAsBoardMember() {
        return workflowSettingService.isEnabled("ENABLE_PAPER_PRINTING_OPTION_FOR_BOARD_MEMBERS", false);
    }

    public boolean canPrintAsSecretary() {
        return workflowSettingService.isEnabled("ENABLE_PAPER_PRINTING_OPTION_FOR_BOARD_SECRETARY", false);
    }
}
