package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.PaperReadState;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.List;

public interface PaperReadStateRepository extends JpaRepository<PaperReadState, Long> {
    Optional<PaperReadState> findByPaperIdAndUserId(Long paperId, Long userId);
    List<PaperReadState> findTop20ByUserIdOrderByLastOpenedAtDesc(Long userId);
}
