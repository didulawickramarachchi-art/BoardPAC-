package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "news_posts")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class NewsPost extends BaseEntity {
    @Column(nullable = false, length = 300) private String title;
    @Column(nullable = false, columnDefinition = "TEXT") private String content;
    @Column(length = 2048) private String imageUrl;
    @ElementCollection
    @CollectionTable(name = "news_post_images", joinColumns = @JoinColumn(name = "post_id"))
    @OrderColumn(name = "display_order")
    @Column(name = "image_url", nullable = false, length = 2048)
    @Builder.Default
    private java.util.List<String> imageUrls = new java.util.ArrayList<>();
    @Column(nullable = false) @Builder.Default private Integer displayOrder = 0;
    @ManyToOne @JoinColumn(name = "created_by", nullable = false) private User createdBy;
}
