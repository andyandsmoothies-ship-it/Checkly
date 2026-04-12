# .NET 8+ JsonWebToken Implicit Handling (CONFIRMED)

- **Problem**: In .NET 8/10, `AddJwtBearer` defaults to `JsonWebTokenHandler` which parses incoming tokens into `JsonWebToken`, NOT `JwtSecurityToken`. Attempting to explicitly cast `(JwtSecurityToken)context.SecurityToken` inside `OnTokenValidated` will throw an `InvalidCastException`.
- **Fix**: Never cast to `JwtSecurityToken`. Always safely read the generic issuance time using `context.SecurityToken.ValidFrom`.

# UserManager DI Resolution in Security Hooks

- **Problem**: Security hooks like `OnTokenValidated` (in `AddJwtBearer`) are configured via inline Lambdas in `Program.cs`, and do not have constructors. 
- **Fix**: Resolve scoped services like `UserManager<AppUser>` directly from the request-scoped DI container using `context.HttpContext.RequestServices.GetRequiredService<UserManager<AppUser>>()`. Because `UserManager` is a `Scoped` service, resolving it from the active `HttpContext` is safe and correct.
