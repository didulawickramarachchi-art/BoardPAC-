package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.agenda.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AgendaService {

    private final MeetingRepository meetingRepository;
    private final AgendaSectionRepository agendaSectionRepository;
    private final AgendaItemRepository agendaItemRepository;
    private final AuditService auditService;

    public AgendaSectionResponse createSection(AgendaSectionRequest request) {
        Meeting meeting = meetingRepository.findById(request.getMeetingId())
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));

        AgendaSection section = AgendaSection.builder()
                .meeting(meeting)
                .title(request.getTitle())
                .numberLabel(request.getNumberLabel())
                .displayOrder(request.getDisplayOrder())
                .build();

        section = agendaSectionRepository.save(section);

        auditService.logInfo("AGENDA", "CREATE_SECTION", "SYSTEM",
                "Section created for meeting " + meeting.getTitle(), "WEB");

        return AgendaSectionResponse.builder()
                .id(section.getId())
                .title(section.getTitle())
                .numberLabel(section.getNumberLabel())
                .displayOrder(section.getDisplayOrder())
                .build();
    }

    public List<AgendaSectionResponse> getSections(Long meetingId) {
        return agendaSectionRepository.findByMeetingIdOrderByDisplayOrderAsc(meetingId)
                .stream()
                .map(section -> AgendaSectionResponse.builder()
                        .id(section.getId())
                        .title(section.getTitle())
                        .numberLabel(section.getNumberLabel())
                        .displayOrder(section.getDisplayOrder())
                        .build())
                .toList();
    }

    @Transactional
    public String deleteSection(Long sectionId) {
        AgendaSection section = agendaSectionRepository.findById(sectionId)
                .orElseThrow(() -> new ResourceNotFoundException("Agenda section not found"));

        List<AgendaItem> sectionItems = agendaItemRepository.findBySectionId(sectionId);
        sectionItems.forEach(item -> item.setSection(null));
        agendaItemRepository.saveAll(sectionItems);

        agendaSectionRepository.delete(section);

        auditService.logInfo("AGENDA", "DELETE_SECTION", "SYSTEM",
                "Agenda section deleted: " + section.getTitle(), "WEB");

        return "Agenda section deleted successfully";
    }

    public AgendaItemResponse createItem(AgendaItemRequest request) {
        Meeting meeting = meetingRepository.findById(request.getMeetingId())
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));

        AgendaSection section = null;
        if (request.getSectionId() != null) {
            section = agendaSectionRepository.findById(request.getSectionId())
                    .orElseThrow(() -> new ResourceNotFoundException("Section not found"));
        }

        AgendaItem item = AgendaItem.builder()
                .meeting(meeting)
                .section(section)
                .itemType(request.getItemType())
                .title(request.getTitle())
                .numberLabel(request.getNumberLabel())
                .displayOrder(request.getDisplayOrder())
                .description(request.getDescription())
                .mediaPath(request.getMediaPath())
                .build();

        item = agendaItemRepository.save(item);

        auditService.logInfo("AGENDA", "CREATE_ITEM", "SYSTEM",
                "Agenda item created: " + item.getTitle(), "WEB");

        return mapItem(item);
    }

    public List<AgendaItemResponse> getItems(Long meetingId) {
        return agendaItemRepository.findByMeetingIdOrderByDisplayOrderAsc(meetingId)
                .stream().map(this::mapItem).toList();
    }

    private AgendaItemResponse mapItem(AgendaItem item) {
        return AgendaItemResponse.builder()
                .id(item.getId())
                .itemType(item.getItemType())
                .title(item.getTitle())
                .numberLabel(item.getNumberLabel())
                .displayOrder(item.getDisplayOrder())
                .description(item.getDescription())
                .build();
    }
}
