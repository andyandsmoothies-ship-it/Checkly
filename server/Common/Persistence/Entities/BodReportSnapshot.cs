using System;

namespace Checkly.Api.Common.Persistence.Entities
{
    public class BodReportSnapshot
    {
        public Guid Id { get; set; }
        public DateOnly Date { get; set; }
        public DateTimeOffset ComputedAt { get; set; }
        public string Status { get; set; } = "Complete";
        public string Payload { get; set; } = "{}";
    }
}
