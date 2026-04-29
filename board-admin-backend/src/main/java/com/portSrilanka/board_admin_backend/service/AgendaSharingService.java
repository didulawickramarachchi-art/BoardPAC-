package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.agenda.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AgendaSharingService {

    private final AgendaItemRepository agendaItemRepository;
    private final SharedAgendaItemRepository sharedAgendaItemRepository;
    private final SubcategoryRepository subcategoryRepository;
    private final UserRepository userRepository;
    private final WorkflowSettingService workflowSettingService;
    private final AuditService auditService;

    public SharedAgendaItemResponse shareAgendaItem(ShareAgendaItemRequest request) {
        workflowSettingService.requireEnabled(
                "ENABLE_AGENDA_ITEM_SHARING_WITHIN_SUBCATEGORIES",
                "Agenda item sharing within subcategories is disabled"
        );

        AgendaItem agendaItem = agendaItemRepository.findById(request.getAgendaItemId())
                .orElseThrow(() -> new ResourceNotFoundException("Agenda item not found"));

        Subcategory targetSubcategory = subcategoryRepository.findById(request.getTargetSubcategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Target subcategory not found"));

        User sharedBy = userRepository.findById(request.getSharedByUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        SharedAgendaItem shared = SharedAgendaItem.builder()
                .sourceAgendaItem(agendaItem)
                .sourceSubcategory(agendaItem.getMeeting().getSubcategory())
                .targetSubcategory(targetSubcategory)
                .sharedBy(sharedBy)
                .active(true)
                .build();

        shared = sharedAgendaItemRepository.save(shared);

        auditService.logInfo(
                "AGENDA",
                "SHARE_AGENDA_ITEM",
                sharedBy.getUsername(),
                "Agenda item shared to subcategory " + targetSubcategory.getName(),
                "WEB"
        );

        return map(shared);
    }

    public List<SharedAgendaItemResponse> getSharedToSubcategory(Long subcategoryId) {
        return sharedAgendaItemRepository.findByTargetSubcategoryIdAndActiveTrue(subcategoryId)
                .stream()
                .map(this::map)
                .toList();
    }

    private SharedAgendaItemResponse map(SharedAgendaItem shared) {
        return SharedAgendaItemResponse.builder()
                .id(shared.getId())
                .sourceAgendaItemId(shared.getSourceAgendaItem().getId())
                .sourceAgendaItemTitle(shared.getSourceAgendaItem().getTitle())
                .sourceSubcategoryId(shared.getSourceSubcategory().getId())
                .sourceSubcategoryName(shared.getSourceSubcategory().getName())
                .targetSubcategoryId(shared.getTargetSubcategory().getId())
                .targetSubcategoryName(shared.getTargetSubcategory().getName())
                .sharedByUsername(shared.getSharedBy().getUsername())
                .active(shared.isActive())
                .build();
    }
}