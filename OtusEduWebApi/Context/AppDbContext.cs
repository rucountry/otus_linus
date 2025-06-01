using Microsoft.EntityFrameworkCore;

namespace OtusEduWebApi.Context;

public class AppDbContext : DbContext
{
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<ProductEntity> Products { get; set; } = null!;
}