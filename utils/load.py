import safetensors.torch
import os
import torch

checkpoint_dict_replacements = {
    'cond_stage_model.transformer.embeddings.': 'cond_stage_model.transformer.text_model.embeddings.',
    'cond_stage_model.transformer.encoder.': 'cond_stage_model.transformer.text_model.encoder.',
    'cond_stage_model.transformer.final_layer_norm.': 'cond_stage_model.transformer.text_model.final_layer_norm.',
}
# from sd_webui.modules.sd_models import *
def transform_checkpoint_dict_key(k):
    for text, replacement in checkpoint_dict_replacements.items():
        if k.startswith(text):
            k = replacement + k[len(text):]

    return k
def read_state_dict2(checkpoint_file, print_global_state=False, map_location=None):
    _, extension = os.path.splitext(checkpoint_file)
    if extension.lower() == ".safetensors":
        device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")

        pl_sd = safetensors.torch.load(open(checkpoint_file, 'rb').read())
        pl_sd = {k: v.to(device) for k, v in pl_sd.items()}
    else:
        pl_sd = torch.load(checkpoint_file, map_location="cpu")
        sd = pl_sd["state_dict"]
        return sd

    if print_global_state and "global_step" in pl_sd:
        print(f"Global Step: {pl_sd['global_step']}")

    sd = get_state_dict_from_checkpoint(pl_sd)
    return sd
def get_state_dict_from_checkpoint(pl_sd):
    pl_sd = pl_sd.pop("state_dict", pl_sd)
    pl_sd.pop("state_dict", None)

    sd = {}
    for k, v in pl_sd.items():
        new_key = transform_checkpoint_dict_key(k)

        if new_key is not None:
            sd[new_key] = v

    pl_sd.clear()
    pl_sd.update(sd)

    return pl_sd
# read_state_dict2("/home/wzy/ai-draw/models/CounterfeitV30_v30.safetensors")
