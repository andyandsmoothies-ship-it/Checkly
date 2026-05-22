const fs = require('fs');
const path = require('path');
function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) { 
            results = results.concat(walk(file));
        } else { 
            if (file.endsWith('.cs')) results.push(file);
        }
    });
    return results;
}
let count = 0;
const files = walk(path.join(__dirname, 'tests', 'Checkly.Api.Tests'));
for (const file of files) {
    let content = fs.readFileSync(file, 'utf8');
    let orig = content;
    
    // Replace new Store {
    content = content.replace(/new Store \{/g, 'new Store { Address = new Checkly.Api.Common.Persistence.Entities.StoreAddress { Province = "Unknown" },');
    
    // Replace payloads
    content = content.replace(/new\s*\{\s*name\s*=\s*(.+?)\s*\}/g, 'new { name = $1, province = "Unknown" }');
    content = content.replace(/new\s*\{\s*Name\s*=\s*(.+?)\s*\}/g, 'new { Name = $1, province = "Unknown" }');
    
    // Replace multiline payload in StoreAuthorizationTests.cs
    content = content.replace(/new\r?\n\s*\{\r?\n\s*name\r?\n\s*\}/g, 'new { name, province = "Unknown" }');
    
    // Also new { name } on a single line
    content = content.replace(/new\s*\{\s*name\s*\}/g, 'new { name, province = "Unknown" }');

    if (orig !== content) {
        fs.writeFileSync(file, content, 'utf8');
        count++;
        console.log('Fixed: ' + file);
    }
}
console.log('Total fixed: ' + count);
