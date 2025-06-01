using Microsoft.EntityFrameworkCore;
using OtusEduWebApi;
using OtusEduWebApi.Context;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.ConfigureKestrel(options => {
    options.ListenAnyIP(5000); // Слушать все IP-адреса
});

builder.Services.AddCors(options => 
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Подключение к MySQL через Pomelo
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySql(
        connectionString,
        ServerVersion.AutoDetect(connectionString)
    ));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapGet("/products", async (AppDbContext db) => 
    await db.Products.ToListAsync());

app.MapGet("/products/{id}", async (int id, AppDbContext db) => 
    await db.Products.FindAsync(id) 
        is ProductEntity product 
        ? Results.Ok(product) 
        : Results.NotFound());

app.MapPost("/products", async (ProductEntity product, AppDbContext db) =>
{
    if (string.IsNullOrEmpty(product.Name) || product.Price <= 0)
        return Results.BadRequest("Invalid product data");
    product.Host = Helper.GetLocalIPAddress();
    product.Id = new Random().Next(1,10000);
    db.Products.Add(product);
    await db.SaveChangesAsync();
    return Results.Created($"/products/{product.Id}", product);
});

app.MapPut("/products/{id}", async (int id, ProductEntity updatedProduct, AppDbContext db) =>
{
    if (id != updatedProduct.Id)
        return Results.BadRequest("ID mismatch");
    
    var existingProduct = await db.Products.FindAsync(id);
    if (existingProduct is null) return Results.NotFound();
    
    existingProduct.Name = updatedProduct.Name;
    existingProduct.Price = updatedProduct.Price;
    existingProduct.Host = Helper.GetLocalIPAddress();
    
    await db.SaveChangesAsync();
    return Results.Ok(existingProduct);
});

app.MapDelete("/products/{id}", async (int id, AppDbContext db) =>
{
    var product = await db.Products.FindAsync(id);
    if (product is null) return Results.NotFound();
    
    db.Products.Remove(product);
    await db.SaveChangesAsync();
    return Results.NoContent();
});
app.UseCors("AllowAll");
app.Run();
