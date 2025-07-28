#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
cards.json 格式化脚本
用于格式化和美化 cards.json 文件，使其具有更好的可读性
"""

import json
import os
import sys
from pathlib import Path


def format_json_file(file_path):
    """
    格式化JSON文件
    
    Args:
        file_path (str): JSON文件路径
    """
    try:
        # 读取JSON文件
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 格式化JSON数据
        formatted_json = json.dumps(data, ensure_ascii=False, indent=2)
        
        # 写回文件
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(formatted_json)
        
        print(f"✅ 成功格式化文件: {file_path}")
        print(f"📄 文件大小: {os.path.getsize(file_path)} 字节")
        
    except FileNotFoundError:
        print(f"❌ 错误: 找不到文件 {file_path}")
        return False
    except json.JSONDecodeError as e:
        print(f"❌ 错误: JSON格式错误 - {e}")
        return False
    except Exception as e:
        print(f"❌ 错误: {e}")
        return False
    
    return True


def validate_json_structure(data):
    """
    验证JSON数据结构
    
    Args:
        data (dict): JSON数据
    """
    if not isinstance(data, dict):
        print("❌ 错误: 根节点必须是对象")
        return False
    
    if 'cards' not in data:
        print("❌ 错误: 缺少 'cards' 字段")
        return False
    
    if not isinstance(data['cards'], list):
        print("❌ 错误: 'cards' 必须是数组")
        return False
    
    print(f"📊 卡片数量: {len(data['cards'])}")
    
    # 验证每个卡片的结构
    for i, card in enumerate(data['cards']):
        if not isinstance(card, dict):
            print(f"❌ 错误: 卡片 {i} 必须是对象")
            return False
        
        if 'front' not in card or 'back' not in card:
            print(f"❌ 错误: 卡片 {i} 缺少 'front' 或 'back' 字段")
            return False
        
        # 验证 front 和 back 结构
        for side in ['front', 'back']:
            if not isinstance(card[side], dict):
                print(f"❌ 错误: 卡片 {i} 的 {side} 必须是对象")
                return False
            
            # 检查字段只能是允许的字段
            required_fields = ['title', 'description', 'icon']
            for field in card[side].keys():
                if field not in required_fields:
                    print(f"❌ 错误: 卡片 {i} 的 {side} 包含不允许的字段 '{field}'")
                    print(f"💡 允许的字段: {required_fields}")
                    return False
    
    print("✅ JSON结构验证通过")
    return True


def main():
    """
    主函数
    """
    print("🎯 cards.json 格式化工具")
    print("=" * 40)
    
    # 查找 cards.json 文件
    json_file = "./cards.json"
    
    if not os.path.exists(json_file):
        print(f"❌ 错误: 找不到文件 {json_file}")
        print("💡 请确保脚本在项目根目录下运行")
        return
    
    # 读取并验证JSON结构
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if not validate_json_structure(data):
            return
        
    except Exception as e:
        print(f"❌ 错误: 无法读取文件 - {e}")
        return
    
    # 格式化文件
    if format_json_file(json_file):
        print("\n🎉 格式化完成!")
        print("📝 文件已保存，可以查看格式化后的效果")
    else:
        print("\n💥 格式化失败!")


if __name__ == "__main__":
    main() 
