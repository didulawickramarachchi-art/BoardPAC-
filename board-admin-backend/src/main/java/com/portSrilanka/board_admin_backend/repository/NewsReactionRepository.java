package com.portSrilanka.board_admin_backend.repository;
import com.portSrilanka.board_admin_backend.entity.NewsReaction;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
public interface NewsReactionRepository extends JpaRepository<NewsReaction, Long> {
    List<NewsReaction> findByPostIdIn(List<Long> postIds);
    Optional<NewsReaction> findByPostIdAndUserId(Long postId, Long userId);
}
