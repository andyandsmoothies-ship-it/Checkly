using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Features.Submissions;

public static class TemplateSnapshotBuilder
{
    public static string BuildSnapshot(Template template, List<Group> groups, List<Criterion> criteria)
    {
        var snapshotModel = new TemplateSnapshotModel
        {
            SnapshotVersion = 1,
            Title = template.Title,
            Version = template.Version,
            ScoringLogicConfig = template.ScoringLogicConfig,
            DisplayNoun = template.DisplayNoun,
            Groups = groups.Select(g => new SnapshotGroup
            {
                Id = g.Id,
                Title = g.Title,
                Weight = g.Weight,
                MaxDeductionPoints = g.MaxDeductionPoints,
                MinusPerFault = g.MinusPerFault,
                OrderIndex = g.OrderIndex,
                ParentId = g.ParentId,
                Metadata = g.Metadata,
                Criteria = criteria.Where(c => c.GroupId == g.Id).Select(c => new SnapshotCriterion
                {
                    Id = c.Id,
                    GroupId = c.GroupId,
                    Label = c.Label,
                    InputType = c.InputType,
                    PointsWeight = c.PointsWeight,
                    IsCcp = c.IsCcp,
                    IsRisk = c.IsRisk,
                    MinusImpact = c.MinusImpact,
                    OrderIndex = c.OrderIndex,
                    Metadata = c.Metadata
                }).ToList()
            }).ToList()
        };
        
        return JsonSerializer.Serialize(snapshotModel);
    }
}
