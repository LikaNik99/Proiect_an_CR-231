package com.example.backend_api.model;

import jakarta.persistence.*;

@Entity
@Table(name="restaurant_admins")
@IdClass(RestaurantAdminKey.class)
public class RestaurantAdmin {

    @Id
    @Column(name="user_id")
    private Integer userId;

    @Id
    @Column(name="restaurant_id")
    private Integer restaurantId;

    public Integer getUserId() { return userId; }
    public Integer getRestaurantId() { return restaurantId; }

    public void setUserId(Integer userId) { this.userId = userId; }
    public void setRestaurantId(Integer restaurantId) { this.restaurantId = restaurantId; }
}
