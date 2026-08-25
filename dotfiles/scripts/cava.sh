#!/usr/bin/env bash

cava_config="$HOME/.config/cava/config_waybar"

echo "⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀"

cava -p "$cava_config" 2>/dev/null | awk -F';' '
BEGIN {
    split("⣀ ⣄ ⣤ ⣦ ⣶ ⣷ ⣾ ⣿", dict, " ")
}
{
    # 3. BỘ LỌC TỐI THƯỢNG: Chỉ xử lý nếu dòng có đúng 13 trường dữ liệu
    # (12 giá trị sóng + 1 khoảng trống phía sau dấu chấm phẩy cuối cùng)
    if (NF != 13) next
    
    out = ""
    for (i = 1; i <= 12; i++) {
        out = out dict[$i + 1]
    }
    print out
    fflush(stdout)
}'
