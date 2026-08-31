package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.paper.FavoriteResponse;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import com.portSrilanka.board_admin_backend.security.PermissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service @RequiredArgsConstructor
public class FavoriteService {
    private final UserFavoriteRepository favoriteRepository;
    private final UserRepository userRepository;
    private final MeetingRepository meetingRepository;
    private final PaperRepository paperRepository;
    private final PermissionService permissionService;

    public List<FavoriteResponse> list(String username) {
        User user = user(username);
        return favoriteRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream().map(this::map).toList();
    }

    @Transactional
    public FavoriteResponse add(String type, Long targetId, String username) {
        User user = user(username);
        String normalized = normalize(type);
        verify(user, normalized, targetId);
        UserFavorite favorite = favoriteRepository
                .findByUserIdAndFavoriteTypeAndTargetId(user.getId(), normalized, targetId)
                .orElseGet(() -> favoriteRepository.save(UserFavorite.builder()
                        .user(user).favoriteType(normalized).targetId(targetId).build()));
        return map(favorite);
    }

    @Transactional
    public void remove(String type, Long targetId, String username) {
        User user = user(username);
        favoriteRepository.findByUserIdAndFavoriteTypeAndTargetId(
                user.getId(), normalize(type), targetId).ifPresent(favoriteRepository::delete);
    }

    private void verify(User user, String type, Long targetId) {
        Long subcategoryId = type.equals("MEETING")
                ? meetingRepository.findById(targetId)
                    .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"))
                    .getSubcategory().getId()
                : paperRepository.findById(targetId)
                    .orElseThrow(() -> new ResourceNotFoundException("Paper not found"))
                    .getMeeting().getSubcategory().getId();
        if (!permissionService.hasSubcategoryAccess(user.getId(), subcategoryId))
            throw new AccessDeniedException("User has no access to this item");
    }

    private FavoriteResponse map(UserFavorite favorite) {
        if (favorite.getFavoriteType().equals("MEETING")) {
            Meeting meeting = meetingRepository.findById(favorite.getTargetId())
                    .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
            return FavoriteResponse.builder().favoriteType("MEETING").targetId(meeting.getId())
                    .title(meeting.getTitle()).subtitle(meeting.getMeetingDateTime().toString())
                    .createdAt(favorite.getCreatedAt()).build();
        }
        Paper paper = paperRepository.findById(favorite.getTargetId())
                .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        return FavoriteResponse.builder().favoriteType("PAPER").targetId(paper.getId())
                .title(paper.getTitle()).subtitle(paper.getPaperType().name())
                .createdAt(favorite.getCreatedAt()).build();
    }

    private User user(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private String normalize(String type) {
        String value = type == null ? "" : type.trim().toUpperCase();
        if (!value.equals("MEETING") && !value.equals("PAPER"))
            throw new IllegalArgumentException("Favorite type must be MEETING or PAPER");
        return value;
    }
}
