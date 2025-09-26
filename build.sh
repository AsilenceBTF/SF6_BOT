#!/bin/bash

# 函数：显示用法说明
usage() {
    echo "用法: $0 {build|run}"
    echo "  build - 执行Swift构建"
    echo "  run   - 运行生产环境程序"
    exit 1
}

# 函数：检查.env文件
check_env_file() {
    if [ ! -f .env ]; then
        echo "Error: .env文件不存在，请创建.env文件并配置环境变量" >&2
        exit 1
    fi
}

# 函数：检查端口占用并处理
check_port() {
    local port=8080
    
    # 检查端口是否被占用
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "警告: 端口 $port 已被占用"
        
        # 获取占用端口的进程信息
        local pid=$(lsof -ti:$port)
        local process_info=$(ps -p $pid -o pid,user,command= 2>/dev/null)
        
        if [ -n "$process_info" ]; then
            echo "占用进程信息:"
            echo "$process_info"
        else
            echo "进程PID: $pid"
        fi
        
        # 询问用户是否杀死进程
        while true; do
            read -p "是否杀死该进程并继续执行? (y/n): " choice
            case $choice in
                [Yy]* )
                    echo "正在杀死进程 $pid..."
                    kill -9 $pid
                    # 等待进程完全退出
                    sleep 2
                    # 再次检查端口是否释放
                    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                        echo "错误: 无法释放端口 $port" >&2
                        exit 1
                    else
                        echo "端口 $port 已释放"
                        return 0
                    fi
                    ;;
                [Nn]* )
                    echo "操作取消"
                    exit 0
                    ;;
                * )
                    echo "请输入 y 或 n"
                    ;;
            esac
        done
    else
        echo "端口 $port 可用"
        return 0
    fi
}

# 函数：执行构建
build_project() {
    echo "开始构建项目..."
    check_env_file
    xcrun --toolchain swift swift build --swift-sdk x86_64-swift-linux-musl -c release
    
    if [ $? -eq 0 ]; then
        echo "构建成功完成!"
    else
        echo "构建失败!" >&2
        exit 1
    fi
}

# 函数：运行程序
run_project() {
    echo "启动生产环境服务..."
    check_env_file
    
    # 检查端口占用（只在run命令时检查）
    check_port
    
    # 检查可执行文件是否存在
    if [ ! -f .build/release/hello ]; then
        echo "错误: 可执行文件不存在，请先执行构建命令: $0 build" >&2
        exit 1
    fi
    
    echo "启动服务..."
    ./hello --env production
}

# 主程序
main() {
    # 检查参数数量
    if [ $# -ne 1 ]; then
        echo "错误: 需要1个参数" >&2
        usage
    fi

    case "$1" in
        build)
            build_project
            ;;
        run)
            run_project
            ;;
        *)
            echo "错误: 未知参数 '$1'" >&2
            usage
            ;;
    esac
}

# 执行主程序
main "$@"
