package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.privilege.PrivilegeAssignRequest;
import com.portSrilanka.board_admin_backend.entity.Category;
import com.portSrilanka.board_admin_backend.entity.BoardNotification;
import com.portSrilanka.board_admin_backend.entity.Role;
import com.portSrilanka.board_admin_backend.entity.Subcategory;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.entity.UserSubcategoryAccess;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.repository.SubcategoryRepository;
import com.portSrilanka.board_admin_backend.repository.NotificationReactionRepository;
import com.portSrilanka.board_admin_backend.repository.NotificationReplyRepository;
import com.portSrilanka.board_admin_backend.repository.NotificationRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.repository.UserSubcategoryAccessRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.Set;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PrivilegeServiceTest {

    @Test
    void assigningPrivilegeShouldNotifyTheUserForThatSubcategory() {
        UserSubcategoryAccessRepository accessRepository = mock(UserSubcategoryAccessRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        SubcategoryRepository subcategoryRepository = mock(SubcategoryRepository.class);
        AuditService auditService = mock(AuditService.class);
        NotificationService notificationService = mock(NotificationService.class);
        PrivilegeService service = new PrivilegeService(
                accessRepository, userRepository, subcategoryRepository,
                auditService, notificationService);

        Role memberRole = Role.builder().name(SystemRole.MEMBER).build();
        User user = User.builder()
                .username("member")
                .status(UserStatus.ACTIVE)
                .roles(Set.of(memberRole))
                .build();
        Category category = Category.builder().name("Finance").build();
        Subcategory subcategory = Subcategory.builder()
                .name("Audit")
                .category(category)
                .build();
        PrivilegeAssignRequest request = new PrivilegeAssignRequest();
        request.setUserId(4L);
        request.setSubcategoryId(9L);

        when(userRepository.findById(4L)).thenReturn(Optional.of(user));
        when(subcategoryRepository.findById(9L)).thenReturn(Optional.of(subcategory));
        when(accessRepository.save(any(UserSubcategoryAccess.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        service.assign(request);

        verify(notificationService).notifySubcategoryPrivilegeAssigned(user, subcategory);
    }

    @Test
    void subcategoryPrivilegeNotificationShouldCreateNotificationAndSendEmail() {
        EmailService emailService = mock(EmailService.class);
        NotificationRepository notificationRepository = mock(NotificationRepository.class);
        NotificationService notificationService = new NotificationService(
                emailService,
                mock(WorkflowSettingService.class),
                notificationRepository,
                mock(NotificationReplyRepository.class),
                mock(NotificationReactionRepository.class),
                mock(UserRepository.class)
        );
        User user = User.builder()
                .username("member")
                .firstName("Nimal")
                .boardEmail("nimal@example.com")
                .status(UserStatus.ACTIVE)
                .build();
        user.setId(4L);
        Category category = Category.builder().name("Finance").build();
        Subcategory subcategory = Subcategory.builder()
                .name("Audit")
                .category(category)
                .build();

        notificationService.notifySubcategoryPrivilegeAssigned(user, subcategory);

        verify(notificationRepository).save(any(BoardNotification.class));
        verify(emailService).sendEmail(
                eq("nimal@example.com"),
                eq("BoardPAC subcategory access granted"),
                contains("Audit under Finance")
        );
    }
}
