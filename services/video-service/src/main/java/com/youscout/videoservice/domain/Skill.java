package com.youscout.videoservice.domain;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "skills")
public class Skill {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(unique = true, nullable = false, length = 100)
    private String name;

    @Column(name = "icon_name", length = 100)
    private String iconName;

    @Column(name = "is_active")
    private Boolean isActive = true;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getIconName() { return iconName; }
    public void setIconName(String iconName) { this.iconName = iconName; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
}
