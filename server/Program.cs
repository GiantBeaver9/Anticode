using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Anticode.Server.Data;
using Anticode.Server.Models;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ----- Database -----
var dbPath = builder.Configuration["DATABASE_PATH"]
    ?? Environment.GetEnvironmentVariable("DATABASE_PATH")
    ?? Path.Combine(AppContext.BaseDirectory, "data", "assessment.db");
Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(dbPath))!);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite($"Data Source={dbPath}"));

// ----- Auth (single shared password, cookie session) -----
builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.Cookie.Name = "anticode_session";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        options.ExpireTimeSpan = TimeSpan.FromDays(30);
        options.SlidingExpiration = true;
        // API-style responses instead of redirects to a login page.
        options.Events.OnRedirectToLogin = ctx =>
        {
            ctx.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return Task.CompletedTask;
        };
        options.Events.OnRedirectToAccessDenied = ctx =>
        {
            ctx.Response.StatusCode = StatusCodes.Status403Forbidden;
            return Task.CompletedTask;
        };
    });
builder.Services.AddAuthorization();

var app = builder.Build();

// Create the database/schema on first run.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

app.UseAuthentication();
app.UseAuthorization();

// Serve the built Svelte SPA from wwwroot in production.
app.UseDefaultFiles();
app.UseStaticFiles();

var appPassword = builder.Configuration["APP_PASSWORD"]
    ?? Environment.GetEnvironmentVariable("APP_PASSWORD");

// ============================ AUTH ============================
var auth = app.MapGroup("/api/auth");

auth.MapPost("/login", async (LoginRequest body, HttpContext ctx) =>
{
    if (string.IsNullOrEmpty(appPassword))
        return Results.Json(new { error = "Server is missing APP_PASSWORD configuration." }, statusCode: 500);

    if (string.IsNullOrEmpty(body.Password) || body.Password != appPassword)
        return Results.Json(new { error = "Incorrect password." }, statusCode: 401);

    var claims = new List<Claim> { new(ClaimTypes.Name, "owner") };
    var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
    await ctx.SignInAsync(
        CookieAuthenticationDefaults.AuthenticationScheme,
        new ClaimsPrincipal(identity));

    return Results.Ok(new { ok = true });
});

auth.MapPost("/logout", async (HttpContext ctx) =>
{
    await ctx.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
    return Results.Ok(new { ok = true });
});

auth.MapGet("/me", (HttpContext ctx) =>
    Results.Ok(new { authenticated = ctx.User.Identity?.IsAuthenticated ?? false }));

// ============================ PROJECTS ============================
var projects = app.MapGroup("/api/projects").RequireAuthorization();

// List all projects, each with nested updates (newest first).
projects.MapGet("/", async (AppDbContext db) =>
{
    var list = await db.Projects
        .Include(p => p.Updates)
        .OrderByDescending(p => p.CreatedAt)
        .ToListAsync();

    foreach (var p in list)
        p.Updates = p.Updates.OrderByDescending(u => u.CreatedAt).ToList();

    return Results.Ok(list);
});

// Create a project.
projects.MapPost("/", async (ProjectRequest body, AppDbContext db) =>
{
    var name = (body.Name ?? string.Empty).Trim();
    if (string.IsNullOrEmpty(name))
        return Results.Json(new { error = "Project name is required." }, statusCode: 400);

    var now = DateTime.UtcNow;
    var project = new Project
    {
        Id = Guid.NewGuid(),
        Name = name,
        Description = body.Description ?? string.Empty,
        FirstPassCompletion = body.FirstPassCompletion ?? false,
        EstimatedEngineerHours = body.EstimatedEngineerHours ?? 0,
        EstimatedAgentHours = body.EstimatedAgentHours ?? 0,
        PercentComplete = Clamp(body.PercentComplete ?? 0),
        Bugs = body.Bugs ?? 0,
        CreatedAt = now,
        UpdatedAt = now,
    };

    db.Projects.Add(project);
    await db.SaveChangesAsync();
    return Results.Created($"/api/projects/{project.Id}", project);
});

// Update a project.
projects.MapPut("/{id:guid}", async (Guid id, ProjectRequest body, AppDbContext db) =>
{
    var project = await db.Projects.FindAsync(id);
    if (project is null)
        return Results.Json(new { error = "Project not found." }, statusCode: 404);

    if (body.Name is not null)
    {
        var name = body.Name.Trim();
        if (string.IsNullOrEmpty(name))
            return Results.Json(new { error = "Project name is required." }, statusCode: 400);
        project.Name = name;
    }
    if (body.Description is not null) project.Description = body.Description;
    if (body.FirstPassCompletion is not null) project.FirstPassCompletion = body.FirstPassCompletion.Value;
    if (body.EstimatedEngineerHours is not null) project.EstimatedEngineerHours = body.EstimatedEngineerHours.Value;
    if (body.EstimatedAgentHours is not null) project.EstimatedAgentHours = body.EstimatedAgentHours.Value;
    if (body.PercentComplete is not null) project.PercentComplete = Clamp(body.PercentComplete.Value);
    if (body.Bugs is not null) project.Bugs = body.Bugs.Value;
    project.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();
    return Results.Ok(project);
});

// Delete a project (updates cascade).
projects.MapDelete("/{id:guid}", async (Guid id, AppDbContext db) =>
{
    var project = await db.Projects.FindAsync(id);
    if (project is null)
        return Results.Json(new { error = "Project not found." }, statusCode: 404);

    db.Projects.Remove(project);
    await db.SaveChangesAsync();
    return Results.Ok(new { ok = true });
});

// Add an update under a project.
projects.MapPost("/{id:guid}/updates", async (Guid id, UpdateRequest body, AppDbContext db) =>
{
    var project = await db.Projects.FindAsync(id);
    if (project is null)
        return Results.Json(new { error = "Project not found." }, statusCode: 404);

    var now = DateTime.UtcNow;
    var pct = Clamp(body.PercentComplete ?? 0);
    var eng = body.EstimatedEngHours ?? 0;
    var agent = body.EstimatedAgentHours ?? 0;

    var update = new ProjectUpdate
    {
        Id = Guid.NewGuid(),
        ProjectId = id,
        PercentComplete = pct,
        EstimatedEngHours = eng,
        EstimatedAgentHours = agent,
        EstimatedTimeToCompletion = body.EstimatedTimeToCompletion ?? string.Empty,
        Notes = body.Notes ?? string.Empty,
        BugsFound = body.BugsFound ?? 0,
        BugsFixed = body.BugsFixed ?? 0,
        CreatedAt = now,
    };
    db.Updates.Add(update);

    // Roll the latest update's headline figures up onto the parent project.
    project.PercentComplete = pct;
    project.EstimatedEngineerHours = eng;
    project.EstimatedAgentHours = agent;
    project.UpdatedAt = now;

    await db.SaveChangesAsync();
    return Results.Created($"/api/updates/{update.Id}", update);
});

// ============================ UPDATES ============================
app.MapDelete("/api/updates/{id:guid}", async (Guid id, AppDbContext db) =>
{
    var update = await db.Updates.FindAsync(id);
    if (update is null)
        return Results.Json(new { error = "Update not found." }, statusCode: 404);

    db.Updates.Remove(update);
    await db.SaveChangesAsync();
    return Results.Ok(new { ok = true });
}).RequireAuthorization();

// ============================ CALENDAR ============================
var events = app.MapGroup("/api/events").RequireAuthorization();

// List events, optionally bounded to a [from, to] window. The window matches
// any event that overlaps it, so multi-day events show up in every month they
// touch. Both bounds are optional.
events.MapGet("/", async (AppDbContext db, DateTime? from, DateTime? to) =>
{
    var q = db.CalendarEvents.AsQueryable();
    if (from is not null) q = q.Where(e => e.EndsAt >= from);
    if (to is not null) q = q.Where(e => e.StartsAt <= to);
    var list = await q.OrderBy(e => e.StartsAt).ToListAsync();
    return Results.Ok(list);
});

// Create an event.
events.MapPost("/", async (CalendarEventRequest body, AppDbContext db) =>
{
    var title = (body.Title ?? string.Empty).Trim();
    if (string.IsNullOrEmpty(title))
        return Results.Json(new { error = "Event title is required." }, statusCode: 400);
    if (body.StartsAt is null)
        return Results.Json(new { error = "Event start time is required." }, statusCode: 400);

    var starts = body.StartsAt.Value;
    var ends = body.EndsAt ?? starts;
    if (ends < starts) ends = starts;

    var now = DateTime.UtcNow;
    var ev = new CalendarEvent
    {
        Id = Guid.NewGuid(),
        Title = title,
        Notes = body.Notes ?? string.Empty,
        Location = body.Location ?? string.Empty,
        Attendees = body.Attendees ?? string.Empty,
        StartsAt = starts,
        EndsAt = ends,
        AllDay = body.AllDay ?? false,
        Color = string.IsNullOrWhiteSpace(body.Color) ? "#5b9dff" : body.Color!.Trim(),
        CreatedAt = now,
        UpdatedAt = now,
    };

    db.CalendarEvents.Add(ev);
    await db.SaveChangesAsync();
    return Results.Created($"/api/events/{ev.Id}", ev);
});

// Update an event.
events.MapPut("/{id:guid}", async (Guid id, CalendarEventRequest body, AppDbContext db) =>
{
    var ev = await db.CalendarEvents.FindAsync(id);
    if (ev is null)
        return Results.Json(new { error = "Event not found." }, statusCode: 404);

    if (body.Title is not null)
    {
        var title = body.Title.Trim();
        if (string.IsNullOrEmpty(title))
            return Results.Json(new { error = "Event title is required." }, statusCode: 400);
        ev.Title = title;
    }
    if (body.Notes is not null) ev.Notes = body.Notes;
    if (body.Location is not null) ev.Location = body.Location;
    if (body.Attendees is not null) ev.Attendees = body.Attendees;
    if (body.StartsAt is not null) ev.StartsAt = body.StartsAt.Value;
    if (body.EndsAt is not null) ev.EndsAt = body.EndsAt.Value;
    if (body.AllDay is not null) ev.AllDay = body.AllDay.Value;
    if (body.Color is not null && !string.IsNullOrWhiteSpace(body.Color)) ev.Color = body.Color.Trim();
    if (ev.EndsAt < ev.StartsAt) ev.EndsAt = ev.StartsAt;
    ev.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();
    return Results.Ok(ev);
});

// Delete an event.
events.MapDelete("/{id:guid}", async (Guid id, AppDbContext db) =>
{
    var ev = await db.CalendarEvents.FindAsync(id);
    if (ev is null)
        return Results.Json(new { error = "Event not found." }, statusCode: 404);

    db.CalendarEvents.Remove(ev);
    await db.SaveChangesAsync();
    return Results.Ok(new { ok = true });
});

// SPA fallback: any non-API route serves index.html so client routing works.
app.MapFallbackToFile("index.html");

app.Run();

static double Clamp(double value) => Math.Min(100, Math.Max(0, value));
