package com.example.backend_api.dto;

public class ReservationDto {
    public int id;
    public int restaurantId;
    public String restaurantName;
    public int tableId;
    public int tableNo;
    public String startDt;
    public String endDt;
    public int persons;
    public int durationMin;
    public String status;
    public String customerName;
    public String customerEmail;

    public ReservationDto(int id, int restaurantId, String restaurantName, int tableId, int tableNo,
                          String startDt, String endDt, int persons, int durationMin, String status,
                          String customerName, String customerEmail) {
        this.id = id; this.restaurantId = restaurantId; this.restaurantName = restaurantName;
        this.tableId = tableId; this.tableNo = tableNo;
        this.startDt = startDt; this.endDt = endDt;
        this.persons = persons; this.durationMin = durationMin; this.status = status;
        this.customerName = customerName; this.customerEmail = customerEmail;
    }
}
