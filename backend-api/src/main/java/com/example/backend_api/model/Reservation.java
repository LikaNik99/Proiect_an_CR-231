package com.example.backend_api.model;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name="reservations")
public class Reservation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(optional=false)
    @JoinColumn(name="restaurant_id")
    private Restaurant restaurant;

    @ManyToOne(optional=false)
    @JoinColumn(name="table_id")
    private DiningTable table;

    @ManyToOne(optional=false)
    @JoinColumn(name="customer_id")
    private User customer;

    @Column(name="start_dt", nullable=false)
    private OffsetDateTime startDt;

    @Column(name="end_dt", nullable=false)
    private OffsetDateTime endDt;

    @Column(nullable=false)
    private int persons;

    @Column(name="duration_min", nullable=false)
    private int durationMin;

    @Enumerated(EnumType.STRING)
    @Column(nullable=false)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    private ReservationStatus status;

    public Integer getId() { return id; }
    public Restaurant getRestaurant() { return restaurant; }
    public DiningTable getTable() { return table; }
    public User getCustomer() { return customer; }
    public OffsetDateTime getStartDt() { return startDt; }
    public OffsetDateTime getEndDt() { return endDt; }
    public int getPersons() { return persons; }
    public int getDurationMin() { return durationMin; }
    public ReservationStatus getStatus() { return status; }

    public void setId(Integer id) { this.id = id; }
    public void setRestaurant(Restaurant restaurant) { this.restaurant = restaurant; }
    public void setTable(DiningTable table) { this.table = table; }
    public void setCustomer(User customer) { this.customer = customer; }
    public void setStartDt(OffsetDateTime startDt) { this.startDt = startDt; }
    public void setEndDt(OffsetDateTime endDt) { this.endDt = endDt; }
    public void setPersons(int persons) { this.persons = persons; }
    public void setDurationMin(int durationMin) { this.durationMin = durationMin; }
    public void setStatus(ReservationStatus status) { this.status = status; }
}
