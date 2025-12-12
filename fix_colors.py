import os
import re

# Define the replacements
replacements = {
    r'AppColors\.primaryOrange': 'AppColors.primaryNeon',
    r'AppColors\.darkOrange': 'AppColors.primaryNeonDark',
    r'AppColors\.orangeGradient': 'AppColors.neonGradient',
}

# Directory to search
lib_dir = r'c:\Users\genti\Progetti\GIGI\lib'

# Counter for replacements
total_replacements = 0
files_modified = 0

# Walk through all .dart files
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            file_path = os.path.join(root, file)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Apply all replacements
                for pattern, replacement in replacements.items():
                    content = re.sub(pattern, replacement, content)
                
                # Only write if content changed
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    files_modified += 1
                    print(f"Modified: {file_path}")
                    
            except Exception as e:
                print(f"Error processing {file_path}: {e}")

print(f"\nTotal files modified: {files_modified}")
