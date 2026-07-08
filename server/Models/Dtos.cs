namespace Anticode.Server.Models;

// ----- Auth -----
public record LoginRequest(string? Password);

// ----- Projects -----
public record ProjectRequest(
    string? Name,
    string? Description,
    bool? FirstPassCompletion,
    double? EstimatedEngineerHours,
    double? EstimatedAgentHours,
    double? PercentComplete,
    int? Bugs
);

// ----- Updates -----
public record UpdateRequest(
    double? PercentComplete,
    double? EstimatedEngHours,
    double? EstimatedAgentHours,
    string? EstimatedTimeToCompletion,
    string? Notes,
    int? BugsFound,
    int? BugsFixed
);

// ----- Calendar -----
public record CalendarEventRequest(
    string? Title,
    string? Notes,
    string? Location,
    string? Attendees,
    DateTime? StartsAt,
    DateTime? EndsAt,
    bool? AllDay,
    string? Color
);
