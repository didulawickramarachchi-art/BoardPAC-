package com.portSrilanka.board_admin_backend.repository;
import com.portSrilanka.board_admin_backend.entity.NewsPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import java.util.List;
public interface NewsPostRepository extends JpaRepository<NewsPost, Long> {
    List<NewsPost> findAllByOrderByDisplayOrderDescCreatedAtDesc();
    List<NewsPost> findAllByOrderByDisplayOrderDescCreatedAtDesc(Pageable pageable);
}
