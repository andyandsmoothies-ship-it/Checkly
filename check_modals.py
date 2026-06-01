import os  
import re  
for root, dirs, files in os.walk('lib'):  
    for file in files:  
        if file.endswith('.dart'):  
            path = os.path.join(root, file)  
            with open(path, 'r', encoding='utf-8') as f:  
                content = f.read()  
            if 'showModalBottomSheet' in content:  
                # Check if Navigator.pop is used  
                if 'Navigator.pop(' in content or 'Navigator.of(context).pop(' in content or 'Navigator.of(ctx).pop(' in content:  
                    print(path)  
