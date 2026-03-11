$baseUrl = "http://localhost:5288/api"
$password = "Test1234!"

$users = @(
    @{ email = "admin@checkly.local"; fullName = "Admin User"; role = "auditor" },
    @{ email = "store_manager@checkly.local"; fullName = "Store Manager"; role = "store_manager" },
    @{ email = "area_manager@checkly.local"; fullName = "Area Manager"; role = "area_manager" }
)

Write-Host ""
Write-Host "=== Registering Users ===" -ForegroundColor Cyan

foreach ($user in $users) {
    $body = @{
        email    = $user.email
        password = $password
        fullName = $user.fullName
        role     = $user.role
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $body
        Write-Host "[OK] $($user.email) ($($user.role)) -> userId: $($response.userId)" -ForegroundColor Green
    }
    catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 409) {
            Write-Host "[SKIP] $($user.email) already exists" -ForegroundColor Yellow
        }
        else {
            Write-Host "[FAIL] $($user.email) -> HTTP $status" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=== All Users ===" -ForegroundColor Cyan
Write-Host "  admin@checkly.local         / $password  (promote to admin via SQL)"
Write-Host "  auditor@checkly.local       / $password  (auditor)"
Write-Host "  store_manager@checkly.local / $password  (store_manager)"
Write-Host "  area_manager@checkly.local  / $password  (area_manager)"
Write-Host ""
Write-Host "NEXT: Promote admin via SQL in pgAdmin:" -ForegroundColor Yellow
Write-Host '  UPDATE "UserRoles" SET "Role" = ''admin'''
Write-Host '  WHERE "UserId" = (SELECT "Id" FROM "AspNetUsers" WHERE "Email" = ''admin@checkly.local'');'
Write-Host ""
