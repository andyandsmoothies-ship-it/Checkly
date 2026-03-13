-- List users with their roles
SELECT u.email, u.user_name, p.full_name,
       string_agg(r."Name", ', ') as roles
FROM "AspNetUsers" u
LEFT JOIN profiles p ON p.email = u.email
LEFT JOIN "AspNetUserRoles" ur ON ur."UserId" = u.id
LEFT JOIN "AspNetRoles" r ON r."Id" = ur."RoleId"
GROUP BY u.email, u.user_name, p.full_name
LIMIT 10;
