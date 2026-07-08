using System.ComponentModel.DataAnnotations;

namespace Anticode.Server.Models;

// A private calendar entry, shared only among whoever knows the app password
// (i.e. you and your family). Times are stored as UTC instants; the client is
// responsible for presenting them in local time.
public class CalendarEvent
{
    [Key]
    public Guid Id { get; set; }

    [Required]
    public string Title { get; set; } = string.Empty;

    public string Notes { get; set; } = string.Empty;

    public string Location { get; set; } = string.Empty;

    // Free-form, comma-separated people (e.g. "Mum, Dad, Ava").
    public string Attendees { get; set; } = string.Empty;

    // For all-day events, StartsAt is midnight of the first day and EndsAt is
    // midnight after the last day; the time components are ignored by the UI.
    public DateTime StartsAt { get; set; }

    public DateTime EndsAt { get; set; }

    public bool AllDay { get; set; }

    // Colour used to tint the event in the calendar grid.
    public string Color { get; set; } = "#5b9dff";

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }
}
