import os
import glob
from PIL import Image

def generate_game_ready():
    target_height = 112  # Altura imponente de Boss (~1.4x os heróis normais)
    
    out_dir = "RelicArena/assets/characters/boss_dev/game_ready"
    os.makedirs(out_dir, exist_ok=True)
    
    # Processa poses de cast e idle
    for category in ["cast", "idle"]:
        pattern = f"RelicArena/assets/characters/boss_dev/{category}/*.png"
        for p in glob.glob(pattern):
            if "test_" in os.path.basename(p):
                continue
            img = Image.open(p)
            scale = target_height / float(img.height)
            target_width = max(16, int(round(img.width * scale)))
            
            # Reamostragem de alta qualidade preservando detalhes do pixel art
            resized = img.resize((target_width, target_height), Image.Resampling.LANCZOS)
            
            name = os.path.basename(p)
            save_path = os.path.join(out_dir, name)
            resized.save(save_path)
            print(f"Game-ready {category}: {name} -> ({target_width}, {target_height})")

if __name__ == "__main__":
    generate_game_ready()
