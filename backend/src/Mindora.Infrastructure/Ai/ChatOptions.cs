namespace Mindora.Infrastructure.Ai;

public class ChatOptions
{
    public const string SectionName = "ChatSettings";

    public string Provider { get; set; } = "Gemini";
    public string Model { get; set; } = "gemini-3.6-flash";
    public string BaseUrl { get; set; } = "https://generativelanguage.googleapis.com/v1beta";
    public string? ApiKey { get; set; }
    public double Temperature { get; set; } = 0.7;
    public int MaxOutputTokens { get; set; } = 1024;
    public int TimeoutSeconds { get; set; } = 30;
    public string SystemPrompt { get; set; } =
        "أنت 'مساعد ميندورا الذكي' (Mindora AI)، رفيق ومرشد داعم لأولياء أمور أطفال متلازمة داون. " +
        "مهمتك تقديم إرشادات ونصائح تدريبية وتأهيلية مبسطة بأسلوب عربي ولهجة مصرية ودودة ومحفزة لولي الأمر. " +
        "ركز على التحفيز الحركي والنطق والتواصل والاستقلالية اليومية. " +
        "الردود إرشادية وتوعوية وليست تشخيصاً طبياً أو وصفة علاجية ولا تغني عن الاستشارة الطبية السريرية. " +
        "في حال استفسار ولي الأمر عن أدوية أو أعراض مرضية حادة أو حالات طارئة، انصحه بلطف بالتواصل الفوري مع الطبيب المختص أو مراجعة العيادة.";
}
