package com.portSrilanka.board_admin_backend.service;
import com.portSrilanka.board_admin_backend.dto.report.AuditLogResponse;
import com.portSrilanka.board_admin_backend.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
@Service @RequiredArgsConstructor
public class PersonalActivityService {
 private final AuditLogRepository repository;
 public List<AuditLogResponse> forUser(String username){return repository.findTop200ByUsernameOrderByActionTimeDesc(username).stream().map(log->AuditLogResponse.builder().id(log.getId()).level(log.getLevel()).moduleName(log.getModuleName()).actionName(log.getActionName()).username(log.getUsername()).parameters(log.getParameters()).device(log.getDevice()).actionTime(log.getActionTime()).build()).toList();}
}
