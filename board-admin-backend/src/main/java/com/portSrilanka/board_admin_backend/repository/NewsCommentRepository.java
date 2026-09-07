package com.portSrilanka.board_admin_backend.repository;
import com.portSrilanka.board_admin_backend.entity.NewsComment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface NewsCommentRepository extends JpaRepository<NewsComment, Long> {
    @EntityGraph(attributePaths = "user")
    List<NewsComment> findByPostIdInOrderByCreatedAtAsc(List<Long> postIds);
}
