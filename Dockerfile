# Set the base image
ARG BASE_IMAGE=pytorch/pytorch:2.11.0-cuda13.0-cudnn9-runtime
FROM ${BASE_IMAGE}

# Set the shell and enable pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set basic environment variables
ENV SHELL=/bin/bash 
ENV PYTHONUNBUFFERED=True 
ENV DEBIAN_FRONTEND=noninteractive

# Set the default workspace directory
ENV RP_WORKSPACE=/workspace

# Set TZ and Locale
ENV TZ=Etc/UTC

# 以及按需安装其他软件
RUN apt-get update && apt-get install -y git git-lfs curl && apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# 安装 ssh 服务，用于支持 VSCode 客户端通过 Remote-SSH 访问开发环境
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y wget unzip openssh-server tzdata && apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN mkdir -p /app/ai-server
WORKDIR /app/ai-server

RUN pip install accelerate transformers==5.7.0 --no-cache --break-system-packages

# diffusers src at 2026-4-30
RUN git clone https://github.com/huggingface/diffusers && cd diffusers && git checkout 2173c55 &&  pip install -e . --no-cache --break-system-packages

ENV CNB_MODEL_PATH=/app/models

# 安装 code-server(VSCode WebIDE 支持)
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${CODESERVER_VERSION} && \
    code-server --install-extension cnbcool.cnb-welcome && \
    code-server --install-extension redhat.vscode-yaml && \
    code-server --install-extension waderyan.gitblame && \
    code-server --install-extension mhutchie.git-graph && \
    code-server --install-extension donjayamanne.githistory && \
    code-server --install-extension cloudstudio.live-server && \
    code-server --install-extension tencent-cloud.coding-copilot && \
    rm -rf $HOME/.cache/code-server/* /root/.config/code-server/logs

# --- VSCode 配置: 禁用预览、设置启动编辑器、禁用 Copilot 欢迎消息 ---
# 修改开始: 专门优化文件打开行为
# "workbench.editor.enablePreview": false  <-- 此行是关键，彻底禁用预览模式，让单击文件总是在新标签页打开
# "workbench.editor.showTabs": "multiple"  <-- 此行为辅助，确保多标签页模式总是开启（通常是默认值，但显式设置更保险）
RUN mkdir -p /root/.local/share/code-server/User \
    && echo '{ \
        "workbench.startupEditor": "readme", \
        "workbench.editor.enablePreview": false, \
        "github.copilot.chat.welcomeMessage": "never", \
        "workbench.editor.showTabs": "multiple" \
    }' > /root/.local/share/code-server/User/settings.json
# 修改结束

# 欢迎页面Banner
COPY logo/logo.txt /etc/logo.txt
RUN echo 'cat /etc/logo.txt' >> /root/.bashrc
RUN echo 'echo -e "\nFor detailed documentation and guides, please visit:\n\033[1;34mhttps://cnb.cool/bigbomb\033[0m and \033[1;34mhttps://cnb.cool/bigbomb\033[0m\n\n"' >> /root/.bashrc

# 指定字符集支持命令行输入中文（根据需要选择字符集）
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8

RUN echo "Hello BigBomb!"
