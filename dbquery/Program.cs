using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

class Program {
    static async Task Main() {
        var json = "{\"templateId\":\"293b6e85-64d5-4560-bf6c-7f72295669b7\",\"storeId\":\"e31fcb4a-466a-4dff-aaa7-3ab2fa672439\",\"clientScore\":0,\"status\":\"completed\",\"idempotencyKey\":\"" + Guid.NewGuid().ToString() + "\",\"answers\":[{\"criteriaId\":\"1e8ae75f-884e-44af-ba45-9eee41c29164\",\"value\":\"conform\",\"numericValue\":null,\"note\":null,\"photoUrl\":null,\"isRepeatedError\":false}]}";
        var client = new HttpClient();
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        var res = await client.PostAsync("http://localhost:5288/api/submissions", content);
        Console.WriteLine($"Status: {res.StatusCode}");
        var body = await res.Content.ReadAsStringAsync();
        Console.WriteLine($"Body: {body}");
    }
}
