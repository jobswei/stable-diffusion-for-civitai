# stable-diffusion-for-civitai
solve the problem that stable diffusion no-webui version can not import civitai models.

stable diffusion 是广为人知的ai图像生成项目。它发布有[webui版本](https://github.com/AUTOMATIC1111/stable-diffusion-webui.git) 以及无[webui的纯代码版本](https://github.com/CompVis/stable-diffusion.git)  
如果你用过无webui版本的话，就会发现它无法读入civitai上的模型，这是一件令人痛苦的事情（毕竟谁不知道C站的强大。。

本项目修复了这个问题，具体操作如下：
* 将utils文件夹拷贝到stable diffusion 的根目录
* 用本项目中的`txt2img.py`替换原项目中的`txt2img.py`文件
* `demo.py`为辅助脚本，也可以直接使用控制台进行图片生成

注意：

* C站下载的模型文件要以`.safetensor`扩展名结尾
* 官网的模型文件以`.ckpt`结尾
* 如有其他来源的模型文件，可以分别尝试两个扩展名。其实问题的本质就在于对于不同扩展名，选取了不同的模型读取方式

## conda 适配
使用conda管理环境并启动
```bash
conda create -n sd-webui python=3.11
conda activate sd-webui

pip install torch==2.5.0 torchvision==0.20.0 torchaudio==2.5.0 --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements.txt

bash webui_conda.sh
```
`scripts/webui_conda.sh`放在sd-webui项目的根目录下。

为了使用 stable diffusion 3，你需要在huggingface下载
```
stable-diffusion-3-medium
sd-vae
t5-v1_1-xxl
```

如有问题欢迎联系3031864345@qq.com