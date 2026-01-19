import json
import os

arb_dir = r"c:\Users\genti\Progetti\GiGi\lib\l10n"
files = [f for f in os.listdir(arb_dir) if f.endswith('.arb')]

def load_keys(filename):
    with open(os.path.join(arb_dir, filename), 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
            return set(k for k in data.keys() if not k.startswith('@'))
        except Exception as e:
            print(f"Error loading {filename}: {e}")
            return set()

base_lang = 'app_en.arb'
base_keys = load_keys(base_lang)

for f in files:
    if f == base_lang: continue
    keys = load_keys(f)
    missing = base_keys - keys
    extra = keys - base_keys
    
    if missing:
        print(f"MISSING in {f}:")
        for k in missing:
            print(f"  - {k}")
    if extra:
        print(f"EXTRA in {f}:")
        for k in extra:
            print(f"  - {k}")
