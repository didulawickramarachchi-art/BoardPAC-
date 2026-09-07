package com.portSrilanka.board_admin_backend.dto.news;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
@Value @Builder
public class NewsResponse {
    Long id; String title; String content; String imageUrl; List<String> imageUrls; Long createdByUserId; String createdByName;
    String createdByProfilePictureUrl; LocalDateTime createdAt; List<Comment> comments;
    Map<String, Long> reactionCounts; String currentReaction;
    @Value @Builder public static class Comment { Long id; Long userId; String userName; String profilePictureUrl; String message; LocalDateTime createdAt; }
}
