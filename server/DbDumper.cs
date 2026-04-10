using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Checkly.Api.Common.Persistence;

class DbDumperApp
{
    static async Task Run()
    {
        var services = new ServiceCollection();
        services.AddLogging(b => b.AddConsole());
        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql("Host=localhost;Database=checkly;Username=postgres;Password=postgres"));
        
        var provider = services.BuildServiceProvider();
        using var scope = provider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var submissions = await db.Submissions
            .OrderByDescending(s => s.CreatedAt)
            .Take(10)
            .Select(s => new {
                s.Id,
                s.TemplateTitle,
                s.Status,
                s.TotalScore,
                s.CreatedAt
            })
            .ToListAsync();

        foreach (var s in submissions)
        {
            Console.WriteLine($"{s.CreatedAt:yyyy-MM-dd HH:mm:ss} | {s.TemplateTitle,-30} | {s.Status,-10} | Score: {s.TotalScore} | ID: {s.Id}");
        }
    }
}
