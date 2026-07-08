using Anticode.Server.Models;
using Microsoft.EntityFrameworkCore;

namespace Anticode.Server.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Project> Projects => Set<Project>();
    public DbSet<ProjectUpdate> Updates => Set<ProjectUpdate>();
    public DbSet<CalendarEvent> CalendarEvents => Set<CalendarEvent>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Project>(e =>
        {
            e.HasMany(p => p.Updates)
                .WithOne(u => u.Project!)
                .HasForeignKey(u => u.ProjectId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ProjectUpdate>(e =>
        {
            e.HasIndex(u => u.ProjectId);
        });

        modelBuilder.Entity<CalendarEvent>(e =>
        {
            e.HasIndex(c => c.StartsAt);
            e.HasIndex(c => c.EndsAt);
        });
    }
}
