SELECT u."Id", u."UserName", u."Email", p."FullName", p."JobTitle", p."Department", p."PhoneNumber"
FROM "AspNetUsers" u
LEFT JOIN "profiles" p ON u."Id" = p."UserId";
