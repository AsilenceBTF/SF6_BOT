#!/bin/bash

# 函数：显示用法说明
usage() {
    echo "用法: $0 {build|run|package}"
    echo "  build   - 执行Swift构建"
    echo "  run     - 运行生产环境程序"
    echo "  package - 打包构建产物（含resources文件）"
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

# 函数：选择构建模式
select_build_mode() {
    echo "请选择构建模式:"
    echo "1) release (生产环境)"
    echo "2) debug (开发调试)"
    
    while true; do
        read -p "请输入选择 (1 或 2): " choice
        case $choice in
            1)
                BUILD_MODE="release"
                echo "选择构建模式: release"
                break
                ;;
            2)
                BUILD_MODE="debug"
                echo "选择构建模式: debug"
                break
                ;;
            *)
                echo "无效选择，请输入 1 或 2"
                ;;
        esac
    done
}

# 函数：获取正确的构建产物路径
get_build_path() {
    local build_mode=$1
    if [ "$build_mode" = "debug" ]; then
        echo ".build/x86_64-swift-linux-musl/debug"
    else
        echo ".build/release"
    fi
}

# 函数：执行构建
build_project() {
    echo "开始构建项目..."
    check_env_file
    
    # 选择构建模式
    select_build_mode
    
    echo "构建配置:"
    echo "  - 模式: $BUILD_MODE"
    echo "  - SDK: x86_64-swift-linux-musl"
    
    # 执行构建命令
    xcrun --toolchain swift swift build --swift-sdk x86_64-swift-linux-musl -c $BUILD_MODE
    
    if [ $? -eq 0 ]; then
        echo "构建成功完成!"
        
        # 获取正确的构建路径
        BUILD_PATH=$(get_build_path $BUILD_MODE)
        echo "可执行文件位置: $BUILD_PATH/SF6_BOT"
        echo "提示: 如需打包上传服务器，请执行: $0 package"
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
    if [ ! -f .build/release/SF6_BOT ]; then
        echo "错误: 可执行文件不存在，请先执行构建命令: $0 build" >&2
        exit 1
    fi
    
    echo "启动服务..."
    ./SF6_BOT --env production
}

# 函数：打包构建产物
package_project() {
    echo "开始打包构建产物..."
    check_env_file
    
    # 询问用户选择打包模式
    echo "请选择打包模式:"
    echo "1) release (生产环境)"
    echo "2) debug (开发调试)"
    
    while true; do
        read -p "请输入选择 (1 或 2): " choice
        case $choice in
            1)
                BUILD_MODE="release"
                echo "选择打包模式: release"
                break
                ;;
            2)
                BUILD_MODE="debug"
                echo "选择打包模式: debug"
                break
                ;;
            *)
                echo "无效选择，请输入 1 或 2"
                ;;
        esac
    done
    
    # 获取正确的构建路径
    BUILD_PATH=$(get_build_path $BUILD_MODE)
    
    # 检查可执行文件是否存在
    if [ ! -f "$BUILD_PATH/SF6_BOT" ]; then
        echo "错误: 可执行文件不存在，请先执行构建命令: $0 build"
        echo "提示: 请确保已构建$BUILD_MODE模式"
        exit 1
    fi
    
    # 创建打包目录
    PACKAGE_DIR="SF6_BOT_package"
    echo "创建打包临时目录: $PACKAGE_DIR"
    rm -rf $PACKAGE_DIR 2>/dev/null
    mkdir -p $PACKAGE_DIR
    
    # 复制可执行文件
    echo "复制可执行文件..."
    cp "$BUILD_PATH/SF6_BOT" $PACKAGE_DIR/
    
    # 复制resources文件
    if [ -d "$BUILD_PATH/SF6_BOT_SF6_BOT.resources" ]; then
        echo "复制resources文件..."
        cp -r "$BUILD_PATH/SF6_BOT_SF6_BOT.resources" $PACKAGE_DIR/
    elif [ -f "$BUILD_PATH/SF6_BOT_SF6_BOT.resources" ]; then
        echo "复制resources文件..."
        cp "$BUILD_PATH/SF6_BOT_SF6_BOT.resources" $PACKAGE_DIR/
    else
        echo "警告: 未找到SF6_BOT_SF6_BOT.resources文件，但仍继续打包"
    fi
    
    # 复制.env文件
    if [ -f .env ]; then
        echo "复制.env文件..."
        cp .env $PACKAGE_DIR/
    fi
    
    # 创建打包归档文件
    PACKAGE_FILENAME="SF6_BOT_$(date +%Y%m%d_%H%M%S)_${BUILD_MODE}.tar.gz"
    echo "创建归档文件: $PACKAGE_FILENAME"
    tar -czf $PACKAGE_FILENAME -C $PACKAGE_DIR .
    
    # 清理临时目录
    echo "清理临时文件..."
    rm -rf $PACKAGE_DIR
    
    echo "打包完成!"
    echo "打包文件位置: $PACKAGE_FILENAME"
    echo "提示: 请将此文件上传到服务器，解压后运行 ./SF6_BOT 即可启动服务"
}

# 主程序
main() {
    # 检查参数数量
    if [ $# -ne 1 ]; then
        usage
    fi
    
    # 根据参数执行不同操作
    case $1 in
        build)
            build_project
            ;;
        run)
            run_project
            ;;
        package)
            package_project
            ;;
        *)
            usage
            ;;
    esac
}

# 执行主程序
main "$@"
