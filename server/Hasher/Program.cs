using System;
using Microsoft.AspNetCore.Identity;

var hasher = new PasswordHasher<object>();
var hash = hasher.HashPassword(null!, "Aa1234567@");
Console.WriteLine(hash);
