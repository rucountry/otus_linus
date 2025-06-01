﻿namespace OtusEduWebApi.Context;

public class ProductEntity
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Host { get; set; }
}