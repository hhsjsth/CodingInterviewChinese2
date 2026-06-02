#!/bin/bash

# 检查是否安装了 enca 或 file 工具
if ! command -v enca &> /dev/null && ! command -v file &> /dev/null; then
    echo "错误: 请先安装 enca 或 file 工具用于编码检测。"
    echo "可以使用命令: sudo apt update && sudo apt install enca"
    exit 1
fi

# 目标目录，默认是当前目录
TARGET_DIR="${1:-.}"

echo "开始遍历目录: $TARGET_DIR (不进行 .bak 备份)"
echo "--------------------------------"

# 使用 find 递归查找 .cpp 和 .h 文件
find "$TARGET_DIR" -type f \( -name "*.cpp" -o -name "*.h" \) | while read -r file; do
    
    # 检测文件编码
    if command -v enca &> /dev/null; then
        encoding=$(enca -L zh_CN -i "$file" 2>/dev/null)
    else
        encoding=$(file -b --mime-encoding "$file")
    fi

    # 判断是否为含有中文特征的传统编码
    if [[ "$encoding" =~ "GB" ]] || [[ "$encoding" =~ "18030" ]] || [[ "$encoding" =~ "8bit" ]] || [[ "$encoding" =~ "ISO-8859" ]]; then
        echo "发现 GB2312/GBK 文件: $file"
        
        # 使用临时变量存储转换后的内容，成功后再覆盖原文件
        if tmp_content=$(iconv -f GB18030 -t UTF-8 "$file" 2>/dev/null); then
            echo "$tmp_content" > "$file"
            echo "   [成功] 已转换为 UTF-8"
        else
            echo "   [错误] $file 转换失败，保持原样"
        fi
    fi
done

echo "--------------------------------"
echo "转换完成！请使用 'git status' 和 'git diff' 检查修改。"
