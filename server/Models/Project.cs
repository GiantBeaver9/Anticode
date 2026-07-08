using System.ComponentModel.DataAnnotations;

namespace Anticode.Server.Models;

public class Project
{
    // The "project id" GUID.
    [Key]
    public Guid Id { get; set; }

    [Required]
    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public bool FirstPassCompletion { get; set; }

    public double EstimatedEngineerHours { get; set; }

    public double EstimatedAgentHours { get; set; }

    // 0 - 100
    public double PercentComplete { get; set; }

    public int Bugs { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public List<ProjectUpdate> Updates { get; set; } = new();
}
