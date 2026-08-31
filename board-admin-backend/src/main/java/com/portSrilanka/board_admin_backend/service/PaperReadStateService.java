package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.paper.PaperReadStateRequest;
import com.portSrilanka.board_admin_backend.dto.paper.PaperReadStateResponse;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import com.portSrilanka.board_admin_backend.security.PermissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PaperReadStateService {
    private final PaperReadStateRepository readStateRepository;
    private final PaperRepository paperRepository;
    private final UserRepository userRepository;
    private final PermissionService permissionService;

    public PaperReadStateResponse get(Long paperId, String username) {
        User user = user(username);
        Paper paper = paper(paperId);
        verifyAccess(user, paper);
        return readStateRepository.findByPaperIdAndUserId(paperId, user.getId())
                .map(this::map)
                .orElse(PaperReadStateResponse.builder()
                        .paperId(paperId).seen(false).lastPage(1).completed(false).build());
    }

    public List<com.portSrilanka.board_admin_backend.dto.paper.RecentPaperResponse> recent(String username) {
        User user = user(username);
        return readStateRepository.findTop20ByUserIdOrderByLastOpenedAtDesc(user.getId())
                .stream()
                .filter(state -> permissionService.hasSubcategoryAccess(
                        user.getId(), state.getPaper().getMeeting().getSubcategory().getId()))
                .map(state -> {
                    Paper paper = state.getPaper();
                    return com.portSrilanka.board_admin_backend.dto.paper.RecentPaperResponse.builder()
                            .paperId(paper.getId()).title(paper.getTitle())
                            .paperType(paper.getPaperType().name()).filePath(paper.getFilePath())
                            .fileName(paper.getFileName()).versionNumber(paper.getVersionNumber())
                            .requiresApproval(paper.isRequiresApproval()).mainPaper(paper.isMainPaper())
                            .agendaItemId(paper.getAgendaItem() == null ? null : paper.getAgendaItem().getId())
                            .lastPage(state.getLastPage()).totalPages(state.getTotalPages())
                            .completed(state.isCompleted()).lastOpenedAt(state.getLastOpenedAt()).build();
                }).toList();
    }

    @Transactional
    public PaperReadStateResponse update(Long paperId, String username, PaperReadStateRequest request) {
        User user = user(username);
        Paper paper = paper(paperId);
        verifyAccess(user, paper);
        int page = request.getLastPage() == null ? 1 : request.getLastPage();
        if (page < 1) throw new BadRequestException("Last page must be positive");
        Integer total = request.getTotalPages();
        if (total != null && total < 1) throw new BadRequestException("Total pages must be positive");
        LocalDateTime now = LocalDateTime.now();
        PaperReadState state = readStateRepository
                .findByPaperIdAndUserId(paperId, user.getId())
                .orElseGet(() -> PaperReadState.builder()
                        .paper(paper).user(user).firstOpenedAt(now).lastPage(1).completed(false).build());
        state.setLastOpenedAt(now);
        state.setLastPage(page);
        state.setTotalPages(total);
        state.setCompleted(total != null && page >= total);
        return map(readStateRepository.save(state));
    }

    private User user(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private Paper paper(Long paperId) {
        return paperRepository.findById(paperId)
                .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
    }

    private void verifyAccess(User user, Paper paper) {
        if (!permissionService.hasSubcategoryAccess(
                user.getId(), paper.getMeeting().getSubcategory().getId())) {
            throw new AccessDeniedException("User has no access to this paper");
        }
    }

    private PaperReadStateResponse map(PaperReadState state) {
        return PaperReadStateResponse.builder()
                .paperId(state.getPaper().getId()).seen(true)
                .firstOpenedAt(state.getFirstOpenedAt()).lastOpenedAt(state.getLastOpenedAt())
                .lastPage(state.getLastPage()).totalPages(state.getTotalPages())
                .completed(state.isCompleted()).build();
    }
}
