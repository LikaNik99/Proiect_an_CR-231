package com.example.backend_api.model;

import jakarta.persistence.*;

@Entity
@Table(name = "dining_tables")
public class DiningTable {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(optional = false)
    @JoinColumn(name="restaurant_id")
    private Restaurant restaurant;

    @Column(name="table_no", nullable = false)
    private int tableNo;

    @Column(nullable = false)
    private int seats;

    public Integer getId() { return id; }
    public Restaurant getRestaurant() { return restaurant; }
    public int getTableNo() { return tableNo; }
    public int getSeats() { return seats; }

    public void setId(Integer id) { this.id = id; }
    public void setRestaurant(Restaurant restaurant) { this.restaurant = restaurant; }
    public void setTableNo(int tableNo) { this.tableNo = tableNo; }
    public void setSeats(int seats) { this.seats = seats; }
}
