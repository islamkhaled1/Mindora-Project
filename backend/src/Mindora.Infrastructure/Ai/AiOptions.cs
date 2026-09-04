namespace Mindora.Infrastructure.Ai;

public class AiOptions
{
    public const string SectionName = "AiSettings";

    public string Provider { get; set; } = "Mock";
    public int TimeoutSeconds { get; set; } = 4;
    public string? Endpoint { get; set; }
    public string? ApiKey { get; set; }
}
