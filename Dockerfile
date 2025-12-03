FROM python:3.11-slim

WORKDIR /app

# 防止 Python 缓冲
ENV PYTHONUNBUFFERED=1

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件并安装
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 复制项目代码
COPY . .

# 暴露端口
EXPOSE 8000

# 使用 adk web 启动
CMD ["adk", "web", "--host", "0.0.0.0", "--port", "8000"]