#批量pull镜像，并docker save到本地
import os
import subprocess

# 读取txt文件中的镜像地址
with open('docker_images.txt', 'r') as f:
 image_urls = f.readlines()

# 删除文件末尾的换行符
image_urls = [url.strip() for url in image_urls]

# 创建保存镜像的文件夹
if not os.path.exists('docker_images'):
 os.mkdir('docker_images')

# 拉取镜像并保存到文件夹
for url in image_urls:
 print(f'Pulling image: {url}')
 subprocess.run(['docker', 'pull', url])
 print(f'Saving image: {url}')
 result = subprocess.run(['docker', 'save', '-o', f'docker_images/{url.split("/")[-1]}.tar', url], capture_output=True)
 if result.returncode == 0:
     print(f'Image saved successfully: {url}')
 else:
     print(f'Error saving image: {url}')
     print(result.stderr.decode('utf-8'))
