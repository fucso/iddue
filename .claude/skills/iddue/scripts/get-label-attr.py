#!/usr/bin/env python3
"""
labels.yaml から指定ラベルの属性値を取得する

Usage: python3 get-label-attr.py <label_name> <attr> <yaml_path>
Output: 属性値（見つからない場合は空文字列を出力して終了）
"""
import sys
import re


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <label_name> <attr> <yaml_path>", file=sys.stderr)
        sys.exit(1)

    label_name, attr, yaml_path = sys.argv[1], sys.argv[2], sys.argv[3]

    try:
        with open(yaml_path) as f:
            content = f.read()
    except FileNotFoundError:
        sys.exit(0)

    blocks = re.split(r'\n  - ', content)
    for block in blocks:
        name_match = re.search(r'name:\s*["\']?(.*?)["\']?\s*$', block, re.MULTILINE)
        if name_match and name_match.group(1).strip() == label_name:
            attr_match = re.search(
                rf'{re.escape(attr)}:\s*["\']?(.*?)["\']?\s*$', block, re.MULTILINE
            )
            if attr_match:
                print(attr_match.group(1).strip())
            break


if __name__ == '__main__':
    main()
