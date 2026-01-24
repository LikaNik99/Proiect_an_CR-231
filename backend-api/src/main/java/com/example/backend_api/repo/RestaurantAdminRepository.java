package com.example.backend_api.repo;

import com.example.backend_api.model.RestaurantAdmin;
import com.example.backend_api.model.RestaurantAdminKey;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RestaurantAdminRepository extends JpaRepository<RestaurantAdmin, RestaurantAdminKey> {
    List<RestaurantAdmin> findByUserId(Integer userId);
}
