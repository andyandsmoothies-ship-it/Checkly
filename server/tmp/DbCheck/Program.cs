using Npgsql;
using System;
using System.Text;
using System.Threading.Tasks;

// Set console encoding to UTF8 to handle Vietnamese characters
Console.OutputEncoding = Encoding.UTF8;

var connString = "Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@;";
await using var conn = new NpgsqlConnection(connString);
await conn.OpenAsync();

var sqlTemplate = "SELECT id, title, scoring_logic_config, type, display_noun FROM templates ORDER BY created_at ASC LIMIT 1;";
await using var cmdTemplate = new NpgsqlCommand(sqlTemplate, conn);
await using var readerTemplate = await cmdTemplate.ExecuteReaderAsync();

if (await readerTemplate.ReadAsync())
{
    var templateId = readerTemplate.GetGuid(0);
    Console.WriteLine("=== FIRST TEMPLATE IN DB ===");
    Console.WriteLine($"ID: {templateId}");
    Console.WriteLine($"Title: {readerTemplate.GetString(1)}");
    Console.WriteLine($"ScoringConfig: {(readerTemplate.IsDBNull(2) ? "NULL" : readerTemplate.GetString(2))}");
    Console.WriteLine($"Type: {readerTemplate.GetString(3)}");
    Console.WriteLine($"DisplayNoun: {(readerTemplate.IsDBNull(4) ? "NULL" : readerTemplate.GetString(4))}");
    
    await readerTemplate.CloseAsync();

    Console.WriteLine("\n=== GROUPS & CRITERIA ===");
    var sqlCriteria = @"
        SELECT g.title as group, c.label, c.input_type, c.points_weight, c.minus_impact 
        FROM groups g 
        JOIN criteria c ON g.id = c.group_id 
        WHERE g.template_id = @id 
        ORDER BY g.order_index, c.order_index 
        LIMIT 5;";
    
    await using var cmdCriteria = new NpgsqlCommand(sqlCriteria, conn);
    cmdCriteria.Parameters.AddWithValue("id", templateId);
    await using var readerCriteria = await cmdCriteria.ExecuteReaderAsync();
    
    while (await readerCriteria.ReadAsync())
    {
        Console.WriteLine($"- Group: {readerCriteria.GetString(0)}");
        Console.WriteLine($"  Label: {readerCriteria.GetString(1)}");
        Console.WriteLine($"  InputType: {readerCriteria.GetString(2)} points={readerCriteria.GetDecimal(3)}");
        Console.WriteLine($"  MinusImpact: {(readerCriteria.IsDBNull(4) ? "NULL" : readerCriteria.GetDecimal(4).ToString())}");
        Console.WriteLine();
    }
}
else
{
    Console.WriteLine("No templates found in database.");
}
