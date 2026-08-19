package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.report.MeetingHistoryReportResponse;
import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.enums.MeetingStatus;
import com.portSrilanka.board_admin_backend.enums.MeetingType;
import com.portSrilanka.board_admin_backend.repository.MeetingRepository;
import lombok.RequiredArgsConstructor;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MeetingHistoryReportService {
    private final MeetingRepository meetingRepository;
    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    @Transactional(readOnly = true)
    public List<MeetingHistoryReportResponse> getReport(
            Long categoryId, Long subcategoryId, LocalDate from, LocalDate to) {
        LocalDateTime now = LocalDateTime.now();
        return meetingRepository.findAll().stream()
                .filter(meeting -> meeting.getType() == MeetingType.MEETING)
                .filter(meeting -> meeting.getStatus() == MeetingStatus.CLOSED
                        || meeting.getStatus() == MeetingStatus.LAST
                        || meeting.getStatus() == MeetingStatus.CANCELLED
                        || meeting.getMeetingDateTime().isBefore(now))
                .filter(meeting -> categoryId == null || meeting.getCategory().getId().equals(categoryId))
                .filter(meeting -> subcategoryId == null || meeting.getSubcategory().getId().equals(subcategoryId))
                .filter(meeting -> from == null || !meeting.getMeetingDateTime().toLocalDate().isBefore(from))
                .filter(meeting -> to == null || !meeting.getMeetingDateTime().toLocalDate().isAfter(to))
                .sorted((a, b) -> b.getMeetingDateTime().compareTo(a.getMeetingDateTime()))
                .map(this::map)
                .toList();
    }

    @Transactional(readOnly = true)
    public byte[] generatePdf(Long categoryId, Long subcategoryId, LocalDate from, LocalDate to) {
        List<MeetingHistoryReportResponse> meetings = getReport(categoryId, subcategoryId, from, to);
        List<String> lines = new ArrayList<>();
        lines.add("BOARD MEETING HISTORY REPORT");
        lines.add("Period: " + (from == null ? "All" : from) + " to " + (to == null ? "Present" : to));
        lines.add("Total meetings: " + meetings.size());
        lines.add("");
        for (MeetingHistoryReportResponse meeting : meetings) {
            lines.add(meeting.getTitle());
            lines.add("Date: " + meeting.getMeetingDateTime().format(DATE_TIME) + "   Status: " + meeting.getStatus());
            lines.add("Category: " + meeting.getCategoryName() + "   Subcategory: " + meeting.getSubcategoryName());
            lines.add("Location: " + value(meeting.getLocation()));
            lines.add("Description: " + value(meeting.getDescription()));
            lines.add("Board papers (" + meeting.getPapers().size() + "):");
            if (meeting.getPapers().isEmpty()) lines.add("  - None");
            for (MeetingHistoryReportResponse.PaperSummary paper : meeting.getPapers()) {
                lines.add("  - " + paper.getTitle() + " | " + paper.getPaperType()
                        + " | Ref: " + value(paper.getReferenceNumber())
                        + " | Version: " + (paper.getVersionNumber() == null ? 1 : paper.getVersionNumber()));
            }
            lines.add("");
        }
        return renderPdf(lines);
    }

    private MeetingHistoryReportResponse map(Meeting meeting) {
        return MeetingHistoryReportResponse.builder()
                .id(meeting.getId())
                .title(meeting.getTitle())
                .status(meeting.getStatus().name())
                .meetingDateTime(meeting.getMeetingDateTime())
                .location(meeting.getLocation())
                .description(meeting.getDescription())
                .categoryId(meeting.getCategory().getId())
                .categoryName(displayName(meeting.getCategory().getDisplayName(), meeting.getCategory().getName()))
                .subcategoryId(meeting.getSubcategory().getId())
                .subcategoryName(displayName(meeting.getSubcategory().getDisplayName(), meeting.getSubcategory().getName()))
                .papers(meeting.getPapers().stream().map(paper -> MeetingHistoryReportResponse.PaperSummary.builder()
                        .id(paper.getId())
                        .title(paper.getTitle())
                        .paperType(paper.getPaperType().name())
                        .referenceNumber(paper.getReferenceNumber())
                        .versionNumber(paper.getVersionNumber())
                        .build()).toList())
                .build();
    }

    private byte[] renderPdf(List<String> sourceLines) {
        try (PDDocument document = new PDDocument(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            PDType1Font regular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
            PDType1Font bold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
            PDPage page = null;
            PDPageContentStream content = null;
            float y = 0;
            for (String source : sourceLines) {
                for (String line : wrap(source, 100)) {
                    if (page == null || y < 55) {
                        if (content != null) content.close();
                        page = new PDPage(PDRectangle.A4);
                        document.addPage(page);
                        content = new PDPageContentStream(document, page);
                        y = 790;
                    }
                    content.beginText();
                    content.setFont(source.equals("BOARD MEETING HISTORY REPORT") ? bold : regular,
                            source.equals("BOARD MEETING HISTORY REPORT") ? 16 : 10);
                    content.newLineAtOffset(45, y);
                    content.showText(line.replaceAll("[^\\x20-\\x7E]", ""));
                    content.endText();
                    y -= source.equals("BOARD MEETING HISTORY REPORT") ? 24 : 14;
                }
            }
            if (content != null) content.close();
            document.save(output);
            return output.toByteArray();
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to generate meeting history PDF", exception);
        }
    }

    private List<String> wrap(String text, int width) {
        String clean = value(text);
        List<String> result = new ArrayList<>();
        while (clean.length() > width) {
            int split = clean.lastIndexOf(' ', width);
            if (split < 1) split = width;
            result.add(clean.substring(0, split));
            clean = clean.substring(split).trim();
        }
        result.add(clean);
        return result;
    }

    private String value(String value) {
        return value == null || value.isBlank() ? "-" : value.trim();
    }

    private String displayName(String displayName, String name) {
        return displayName == null || displayName.isBlank() ? name : displayName.trim();
    }
}
