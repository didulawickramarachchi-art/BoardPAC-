package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.agenda.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AgendaService {

    private final MeetingRepository meetingRepository;
    private final AgendaSectionRepository agendaSectionRepository;
    private final AgendaItemRepository agendaItemRepository;
    private final PaperRepository paperRepository;
    private final AuditService auditService;

    public AgendaSectionResponse createSection(AgendaSectionRequest request) {
        Meeting meeting = meetingRepository.findById(request.getMeetingId())
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));

        AgendaSection section = AgendaSection.builder()
                .meeting(meeting)
                .title(request.getTitle())
                .numberLabel(String.valueOf(agendaSectionRepository.countByMeetingId(request.getMeetingId()) + 1))
                .displayOrder((int) agendaSectionRepository.countByMeetingId(request.getMeetingId()) + 1)
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

    @Transactional
    public List<AgendaSectionResponse> getSections(Long meetingId) {
        List<AgendaSection> sections = agendaSectionRepository.findByMeetingIdOrderByDisplayOrderAsc(meetingId);
        for (int index = 0; index < sections.size(); index++) {
            sections.get(index).setDisplayOrder(index + 1);
            sections.get(index).setNumberLabel(String.valueOf(index + 1));
        }
        agendaSectionRepository.saveAll(sections);
        renumberItems(meetingId);
        return sections
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
    public List<AgendaSectionResponse> reorderSections(Long meetingId, List<Long> orderedIds) {
        List<AgendaSection> sections = agendaSectionRepository.findByMeetingIdOrderByDisplayOrderAsc(meetingId);
        if (orderedIds == null || orderedIds.size() != sections.size()) {
            throw new IllegalArgumentException("The complete agenda section order is required");
        }
        Map<Long, AgendaSection> byId = new HashMap<>();
        sections.forEach(section -> byId.put(section.getId(), section));
        for (int index = 0; index < orderedIds.size(); index++) {
            AgendaSection section = byId.remove(orderedIds.get(index));
            if (section == null) throw new IllegalArgumentException("Invalid agenda section order");
            section.setDisplayOrder(index + 1);
            section.setNumberLabel(String.valueOf(index + 1));
        }
        agendaSectionRepository.saveAll(sections);
        renumberItems(meetingId);
        return getSections(meetingId);
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
                .numberLabel(nextItemNumber(meeting.getId(), section))
                .displayOrder(nextItemOrder(meeting.getId(), section))
                .description(request.getDescription())
                .mediaPath(request.getMediaPath())
                .build();

        item = agendaItemRepository.save(item);

        auditService.logInfo("AGENDA", "CREATE_ITEM", "SYSTEM",
                "Agenda item created: " + item.getTitle(), "WEB");

        return mapItem(item);
    }

    @Transactional
    public List<AgendaItemResponse> getItems(Long meetingId) {
        renumberItems(meetingId);
        return agendaItemRepository.findByMeetingIdOrderByDisplayOrderAsc(meetingId)
                .stream().map(this::mapItem).toList();
    }

    @Transactional
    public List<AgendaItemResponse> reorderItems(Long meetingId, List<Long> orderedIds) {
        if (orderedIds == null || orderedIds.isEmpty()) {
            throw new IllegalArgumentException("Agenda item order is required");
        }
        List<AgendaItem> allItems = agendaItemRepository.findByMeetingIdOrderByDisplayOrderAsc(meetingId);
        Map<Long, AgendaItem> byId = new HashMap<>();
        allItems.forEach(item -> byId.put(item.getId(), item));
        Long expectedSectionId = null;
        boolean first = true;
        for (int index = 0; index < orderedIds.size(); index++) {
            AgendaItem item = byId.get(orderedIds.get(index));
            if (item == null) throw new IllegalArgumentException("Invalid agenda item order");
            Long sectionId = item.getSection() == null ? null : item.getSection().getId();
            if (first) {
                expectedSectionId = sectionId;
                first = false;
            } else if (!java.util.Objects.equals(expectedSectionId, sectionId)) {
                throw new IllegalArgumentException("Agenda items must belong to the same section");
            }
            item.setDisplayOrder(index + 1);
        }
        agendaItemRepository.saveAll(orderedIds.stream().map(byId::get).toList());
        renumberItems(meetingId);
        return getItems(meetingId);
    }

    private int nextItemOrder(Long meetingId, AgendaSection section) {
        if (section == null) {
            return (int) agendaItemRepository.findByMeetingIdOrderByDisplayOrderAsc(meetingId).stream()
                    .filter(item -> item.getSection() == null).count() + 1;
        }
        return (int) agendaItemRepository.countByMeetingIdAndSectionId(meetingId, section.getId()) + 1;
    }

    private String nextItemNumber(Long meetingId, AgendaSection section) {
        int order = nextItemOrder(meetingId, section);
        return section == null ? String.valueOf(order) : section.getNumberLabel() + "." + order;
    }

    private void renumberItems(Long meetingId) {
        List<AgendaItem> items = agendaItemRepository.findByMeetingIdOrderByDisplayOrderAsc(meetingId);
        Map<Long, Integer> counters = new HashMap<>();
        int unassigned = 0;
        for (AgendaItem item : items) {
            if (item.getSection() == null) {
                item.setNumberLabel(String.valueOf(++unassigned));
            } else {
                Long sectionId = item.getSection().getId();
                int number = counters.merge(sectionId, 1, Integer::sum);
                item.setNumberLabel(item.getSection().getNumberLabel() + "." + number);
            }
        }
        agendaItemRepository.saveAll(items);
    }

    @Transactional
    public String deleteItem(Long itemId) {
        AgendaItem item = agendaItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Agenda item not found"));

        List<Paper> linkedPapers = paperRepository.findByAgendaItemId(itemId);
        linkedPapers.forEach(paper -> paper.setAgendaItem(null));
        paperRepository.saveAll(linkedPapers);

        agendaItemRepository.delete(item);
        auditService.logInfo("AGENDA", "DELETE_ITEM", "SYSTEM",
                "Agenda item deleted: " + item.getTitle(), "WEB");
        return "Agenda item deleted successfully";
    }

    private AgendaItemResponse mapItem(AgendaItem item) {
        return AgendaItemResponse.builder()
                .id(item.getId())
                .sectionId(item.getSection() != null ? item.getSection().getId() : null)
                .itemType(item.getItemType())
                .title(item.getTitle())
                .numberLabel(item.getNumberLabel())
                .displayOrder(item.getDisplayOrder())
                .description(item.getDescription())
                .build();
    }
}
