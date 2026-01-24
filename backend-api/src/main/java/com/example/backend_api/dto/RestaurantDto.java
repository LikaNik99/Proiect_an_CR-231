package com.example.backend_api.dto;

public class RestaurantDto {
    public int id;
    public String name;
    public String address;
    public String openTime;
    public String closeTime;
    public boolean crossesMidnight;
    public String cuisine;
    public String priceSign;
    public String imageUrl;

    public RestaurantDto(int id, String name, String address, String openTime, String closeTime, boolean crossesMidnight, String cuisine, String priceSign, String imageUrl) {
        this.id = id; this.name = name; this.address = address;
        this.openTime = openTime; this.closeTime = closeTime; this.crossesMidnight = crossesMidnight;
        this.cuisine = cuisine; this.priceSign = priceSign; this.imageUrl = imageUrl;
    }
}
