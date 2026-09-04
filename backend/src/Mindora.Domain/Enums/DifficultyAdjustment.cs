namespace Mindora.Domain.Enums;

/// <summary>
/// Adaptive difficulty recommendation produced after session evaluation.
/// Enables the app to adapt to the child.
/// </summary>
public enum DifficultyAdjustment
{
    Decrease = -1,
    Maintain = 0,
    Increase = 1
}
