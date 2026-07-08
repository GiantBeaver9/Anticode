using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Anticode.Server.Models;

public class ProjectUpdate
{
    // The "update id".
    [Key]
    public Guid Id { get; set; }

    // Reference to the parent project's GUID.
    public Guid ProjectId { get; set; }

    // 0 - 100
    public double PercentComplete { get; set; }

    public double EstimatedEngHours { get; set; }

    public double EstimatedAgentHours { get; set; }

    // Free-form, e.g. "2 weeks", "40h".
    public string EstimatedTimeToCompletion { get; set; } = string.Empty;

    public string Notes { get; set; } = string.Empty;

    public int BugsFound { get; set; }

    public int BugsFixed { get; set; }

    public DateTime CreatedAt { get; set; }

    [JsonIgnore]
    public Project? Project { get; set; }
}
