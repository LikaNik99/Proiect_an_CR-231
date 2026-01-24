package com.example.backend_api.repo;

import com.example.backend_api.model.Reservation;
import com.example.backend_api.model.ReservationStatus;

import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.List;

public interface ReservationRepository extends JpaRepository<Reservation, Integer> {

    @Query("""
        select (count(r) > 0)
        from Reservation r
        where r.table.id = :tableId
          and r.status in :statuses
          and r.startDt < :end
          and r.endDt > :start
    """)
    boolean existsOverlap(@Param("tableId") Integer tableId,
                          @Param("statuses") List<ReservationStatus> statuses,
                          @Param("start") OffsetDateTime start,
                          @Param("end") OffsetDateTime end);

    List<Reservation> findByCustomerIdOrderByStartDtDesc(Integer customerId);

    @Query("""
      select r from Reservation r
      where r.restaurant.id = :rid
      order by r.startDt desc
    """)
    List<Reservation> findByRestaurant(@Param("rid") int restaurantId);
}
