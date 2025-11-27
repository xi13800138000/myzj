#!/bin/bash

# MTProxy Systemd 服务安装脚本
set -e  # 遇到错误立即退出

# 配置变量
SERVICE_NAME="mtproxy"
USER_NAME="root"
WORK_DIR="/home/mtproxy"
SCRIPT_NAME="mtproxy.sh"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 或以 root 用户运行此脚本"
    exit 1
fi

echo "=== 开始安装 MTProxy 系统服务 ==="

# 检查工作目录和脚本
echo "检查工作目录和脚本..."
if [ ! -d "$WORK_DIR" ]; then
    echo "   错误: 工作目录 ${WORK_DIR} 不存在"
    exit 1
fi

if [ ! -f "$WORK_DIR/$SCRIPT_NAME" ]; then
    echo "   错误: 脚本文件 ${WORK_DIR}/${SCRIPT_NAME} 不存在"
    exit 1
fi

# 创建 systemd 服务文件
echo "创建 systemd 服务文件..."
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=MTProxy Service
After=network.target

[Service]
Type=forking
WorkingDirectory=$WORK_DIR
ExecStart=/bin/bash $WORK_DIR/$SCRIPT_NAME start
ExecStop=/bin/bash $WORK_DIR/$SCRIPT_NAME stop
Restart=on-failure
User=$USER_NAME
Group=$USER_NAME

[Install]
WantedBy=multi-user.target
EOF

echo "   服务文件创建在: $SERVICE_FILE"

# 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
systemctl daemon-reload
echo "配置重载完成"

# 测试服务
echo "测试服务..."
if systemctl start "$SERVICE_NAME.service"; then
    echo "   服务启动成功"
else
    echo "   错误: 服务启动失败"
    exit 1
fi

sleep 2  # 等待服务稳定

# 检查服务状态
if systemctl is-active --quiet "$SERVICE_NAME.service"; then
    echo "   服务状态: 运行中"
else
    echo "   错误: 服务未正常运行"
    systemctl status "$SERVICE_NAME.service"
    exit 1
fi

# 启用开机自启
echo "启用开机自启..."
systemctl enable "$SERVICE_NAME.service"
echo "   开机自启已启用"

# 显示最终状态
echo "最终状态检查..."
systemctl status "$SERVICE_NAME.service" --no-pager

echo ""
echo "=== 安装完成 ==="
echo "服务名称: $SERVICE_NAME"
echo "工作目录: $WORK_DIR"
echo "运行用户: $USER_NAME"
echo ""
echo "管理命令:"
echo "  sudo systemctl start $SERVICE_NAME    # 启动服务"
echo "  sudo systemctl stop $SERVICE_NAME     # 停止服务"
echo "  sudo systemctl restart $SERVICE_NAME  # 重启服务"
echo "  sudo systemctl status $SERVICE_NAME   # 查看状态"
echo "  sudo journalctl -u $SERVICE_NAME -f   # 查看日志"
echo ""
echo "MTProxy 服务已安装并配置为开机自动启动。"
