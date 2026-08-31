package com.portSrilanka.board_admin_backend.dto.paper;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data @Builder
public class FavoriteResponse {
    private String favoriteType;
    private Long targetId;
    private String title;
    private String subtitle;
    private LocalDateTime createdAt;
}
