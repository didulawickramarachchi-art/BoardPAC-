package com.portSrilanka.board_admin_backend.repository;
import com.portSrilanka.board_admin_backend.entity.NewsPost;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface NewsPostRepository extends JpaRepository<NewsPost, Long> {
    List<NewsPost> findAllByOrderByDisplayOrderDescCreatedAtDesc();
}
