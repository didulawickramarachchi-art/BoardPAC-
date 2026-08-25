package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.Category;
import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.Subcategory;
import com.portSrilanka.board_admin_backend.repository.MeetingRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class PaperStoragePathServiceTest {

    @Test
    void buildsSafeBoardPaperHierarchyFromMeetingMetadata() {
        MeetingRepository meetings = mock(MeetingRepository.class);
        Category category = Category.builder().name("PORTS").displayName("Port Operations").build();
        Subcategory subcategory = Subcategory.builder().name("SAFETY")
                .displayName("Safety / Security").category(category).build();
        Meeting meeting = Meeting.builder().title("August Board Meeting").category(category)
                .subcategory(subcategory).build();
        when(meetings.findById(42L)).thenReturn(Optional.of(meeting));

        PaperStoragePathService service = new PaperStoragePathService(
                meetings, mock(PaperRepository.class));
        String path = service.buildPath(42L, null, "Board Minutes.pdf");

        assertTrue(path.startsWith(
                "Port_Operations/Safety_-_Security/August_Board_Meeting/BoardPaper/"));
        assertTrue(path.endsWith("_Board_Minutes.pdf"));
        assertFalse(path.contains(".."));
    }

    @Test
    void removesDirectoryTraversalFromFileNames() {
        assertTrue(PaperStoragePathService.sanitizeFileName("../../secret.pdf")
                .equals("secret.pdf"));
    }
}
