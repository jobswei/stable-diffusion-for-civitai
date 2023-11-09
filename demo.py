import os

prompt="A life delayed"

# The civitai model needs the safetensor extension, 
# and the official website model needs the ckpt extension

ckpt="/home/ai-draw/models/CounterfeitV30_v30.safetensors"
# ckpt="/home/ai-draw/models/sd-v1-4.ckpt"

os.system(f"""python scripts/txt2img.py --prompt '{prompt}'  --plms --ddim_steps 25 --ckpt {ckpt}
           --seed 1293666383""")