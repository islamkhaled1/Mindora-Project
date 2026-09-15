namespace Mindora.Domain.Enums;

/// <summary>
/// Client platform initiating authentication or account recovery operations.
/// </summary>
public enum ClientPlatform
{
    SawaApp = 1,
    DoctorDashboard = 2
}

public static class ClientPlatformParser
{
    public static bool TryParse(string? value, out ClientPlatform platform)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            platform = default;
            return false;
        }

        var normalized = value.Trim().ToLowerInvariant().Replace("-", "").Replace("_", "").Replace(" ", "");

        switch (normalized)
        {
            case "sawaapp":
            case "sawa":
            case "parent":
            case "mobile":
            case "flutter":
            case "app":
                platform = ClientPlatform.SawaApp;
                return true;

            case "doctordashboard":
            case "doctor":
            case "dashboard":
            case "web":
            case "clinic":
                platform = ClientPlatform.DoctorDashboard;
                return true;

            default:
                platform = default;
                return false;
        }
    }

    public static ClientPlatform ParseOrDefault(string? value, ClientPlatform defaultPlatform = ClientPlatform.SawaApp)
    {
        return TryParse(value, out var parsed) ? parsed : defaultPlatform;
    }
}
