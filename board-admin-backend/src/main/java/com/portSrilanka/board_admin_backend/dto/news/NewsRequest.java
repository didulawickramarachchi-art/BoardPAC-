package com.portSrilanka.board_admin_backend.dto.news;
import lombok.Data;
@Data public class NewsRequest { private String title; private String content; private String imageUrl; private java.util.List<String> imageUrls; private String message; private String reactionType; private java.util.List<Long> orderedIds; }
