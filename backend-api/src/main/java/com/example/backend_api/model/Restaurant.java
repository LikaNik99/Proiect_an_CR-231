package com.example.backend_api.model;

import jakarta.persistence.*;
import java.time.LocalTime;

@Entity
@Table(name = "restaurants")
public class Restaurant {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false)
    private String name;

    private String address;

    @Column(name="open_time", nullable = false)
    private LocalTime openTime;

    @Column(name="close_time", nullable = false)
    private LocalTime closeTime;

    @Column(name="crosses_midnight", nullable = false)
    private boolean crossesMidnight;

    private String cuisine;

    @Column(name = "price_sign")
    private String priceSign;

    private String imageUrl;

    public Integer getId() { return id; }
    public String getName() { return name; }
    public String getAddress() { return address; }
    public LocalTime getOpenTime() { return openTime; }
    public LocalTime getCloseTime() { return closeTime; }
    public boolean isCrossesMidnight() { return crossesMidnight; }
    public String getCuisine() { return cuisine; }
    public String getPriceSign() { return priceSign; }
    public String getImageUrl() { return imageUrl; }

    public void setId(Integer id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setAddress(String address) { this.address = address; }
    public void setOpenTime(LocalTime openTime) { this.openTime = openTime; }
    public void setCloseTime(LocalTime closeTime) { this.closeTime = closeTime; }
    public void setCrossesMidnight(boolean crossesMidnight) { this.crossesMidnight = crossesMidnight; }
    public void setCuisine(String cuisine) { this.cuisine = cuisine; }
    public void setPriceSign(String priceSign) { this.priceSign = priceSign; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
}
