package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.BoardType;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import jakarta.persistence.*;
import lombok.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false)
    private String password;

    private String salutation;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    private String displayName;

    @Column(nullable = false, unique = true)
    private String boardEmail;

    private String officeEmail;
    private String officeNumber;
    private String mobileNumber;
    private String jobTitle;
    private String profilePictureUrl;

    @Enumerated(EnumType.STRING)
    private BoardType boardType;

    @Enumerated(EnumType.STRING)
    private UserStatus status;

    private boolean twoStepEnabled;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
            name = "user_roles",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    @Builder.Default
    private Set<Role> roles = new HashSet<>();
}