package com.example.backend_api.model;

import java.io.Serializable;
import java.util.Objects;

public class RestaurantAdminKey implements Serializable {
    private Integer userId;
    private Integer restaurantId;

    public RestaurantAdminKey() {}
    public RestaurantAdminKey(Integer userId, Integer restaurantId) {
        this.userId = userId; this.restaurantId = restaurantId;
    }

    @Override public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof RestaurantAdminKey k)) return false;
        return Objects.equals(userId, k.userId) && Objects.equals(restaurantId, k.restaurantId);
    }
    @Override public int hashCode() { return Objects.hash(userId, restaurantId); }
}
