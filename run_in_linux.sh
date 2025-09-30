#!/bin/bash

# 函数：显示用法说明
usage() {
    echo "用法: $0 {unzip|run|help}"
    echo "  unzip   - 解压tar.gz文件到product目录"
    echo "  run     - 运行程序"
    echo "  help    - 显示帮助信息"
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

# 函数：选择执行模式
select_run_mode() {
    echo "请选择执行模式:"
    echo "1) production (生产环境)"
    echo "2) development (开发调试)"

    while true; do
        read -p "请输入选择 (1 或 2): " choice
        case $choice in
            1)
                RUN_MODE="production"
                echo "选择构建模式: production"
                break
                ;;
            2)
                RUN_MODE="development"
                echo "选择构建模式: development"
                break
                ;;
            *)
                echo "无效选择，请输入 1 或 2"
                ;;
        esac
    done
}

# 函数：解压tar.gz文件
unzip_project() {
    echo "开始解压文件..."
    
    # 查找当前目录下的tar.gz文件
    TAR_FILES=($(ls *.tar.gz 2>/dev/null))
    
    # 如果没有找到tar.gz文件
    if [ ${#TAR_FILES[@]} -eq 0 ]; then
        echo "错误: 当前目录下没有找到.tar.gz文件" >&2
        echo "请将SF6_BOT的打包文件上传到当前目录"
        exit 1
    fi
    
    # 如果只有一个tar.gz文件，直接使用
    if [ ${#TAR_FILES[@]} -eq 1 ]; then
        SELECTED_FILE=${TAR_FILES[0]}
        echo "找到一个tar.gz文件: $SELECTED_FILE"
    else
        # 如果有多个tar.gz文件，让用户选择
        echo "找到多个tar.gz文件，请选择要解压的文件:"
        for i in "${!TAR_FILES[@]}"; do
            echo "$((i+1))) ${TAR_FILES[$i]}"
        done
        
        while true; do
            read -p "请输入选择 (1-${#TAR_FILES[@]}): " choice
            if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le ${#TAR_FILES[@]} ]; then
                SELECTED_FILE=${TAR_FILES[$((choice-1))]}
                echo "选择的文件: $SELECTED_FILE"
                break
            else
                echo "无效选择，请输入 1-${#TAR_FILES[@]} 之间的数字"
            fi
        done
    fi
    
    # 创建解压目录 - 修改为product
    DEST_DIR="product"
    echo "创建解压目录: $DEST_DIR"
    rm -rf $DEST_DIR 2>/dev/null
    mkdir -p $DEST_DIR
    
    # 解压文件
    echo "正在解压文件: $SELECTED_FILE..."
    tar -xzf $SELECTED_FILE -C $DEST_DIR
    
    if [ $? -eq 0 ]; then
        echo "解压成功!"
        echo "解压目录: $DEST_DIR"
        echo "提示: 您可以使用 '$0 run' 命令在解压后的目录中运行程序"
    else
        echo "解压失败!" >&2
        exit 1
    fi
}

# 函数：运行程序
run_project() {
    echo "启动服务..."

    # 检查当前目录是否有可执行文件，没有则检查product目录
    if [ ! -f SF6_BOT ] && [ -d product ]; then
        echo "当前目录没有找到可执行文件，正在进入product目录..."
        cd product
    fi
    
    # 检查.env文件
    check_env_file

    # 检查端口占用
    check_port

    # 选择执行模式
    select_run_mode

    # 检查可执行文件是否存在
    if [ ! -f SF6_BOT ]; then
        echo "错误: 可执行文件不存在，请先执行解压命令: $0 unzip" >&2
        exit 1
    fi

    # 确保可执行文件有执行权限
    chmod +x SF6_BOT
    
    echo "启动服务..."
    nohup ./SF6_BOT --env $RUN_MODE > vapor.log 2>&1 &
    echo "日志同步输出到vapor.log"
    echo "服务已在后台启动，进程ID: $!"
}

# 主程序
main() {
    # 检查参数数量
    if [ $# -ne 1 ]; then
        usage
    fi
    
    # 根据参数执行不同操作
    case $1 in
        unzip)
            unzip_project
            ;;
        run)
            run_project
            ;;
        help)
            usage
            ;;
        *)
            usage
            ;;
    esac
}

# 执行主程序
main "$@"