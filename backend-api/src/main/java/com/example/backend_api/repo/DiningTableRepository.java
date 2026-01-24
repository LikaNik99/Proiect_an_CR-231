package com.example.backend_api.repo;

import com.example.backend_api.model.DiningTable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface DiningTableRepository extends JpaRepository<DiningTable, Integer> {
    @Query("""
        select t from DiningTable t
        where t.restaurant.id = :rid and t.seats >= :persons
        order by t.seats asc, t.tableNo asc
    """)
    List<DiningTable> findCandidates(@Param("rid") int restaurantId, @Param("persons") int persons);
}
