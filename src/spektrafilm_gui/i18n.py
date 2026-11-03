from __future__ import annotations

import re
from typing import Any

from qtpy import QtCore, QtWidgets


APP_NAME = 'SpektraStudio'
ORGANIZATION_NAME = 'SpektraStudio'
LANGUAGE_ENGLISH = 'en'
LANGUAGE_CHINESE = 'zh_CN'
LANGUAGE_LABELS = {
    LANGUAGE_ENGLISH: 'English',
    LANGUAGE_CHINESE: '简体中文',
}

_current_language = LANGUAGE_ENGLISH


_ZH: dict[str, str] = {
    'MAIN': '主页',
    'FILM': '胶片',
    'PRINT': '相纸',
    'ADVANCED': '高级',
    'CONFIG': '设置',
    'Import RGB': '导入 RGB 图像',
    'Import Raw': '导入 RAW',
    'Crop and upscale': '裁剪与放大',
    'Input': '输入',
    'Camera': '相机',
    'Profiles': '配置文件',
    'Exposure control': '曝光控制',
    'Enlarger': '放大机',
    'Scanner': '扫描仪',
    'Output': '输出',
    'Halation': '光晕',
    'Couplers': '成色剂',
    'Grain': '颗粒',
    'Camera diffusion': '相机柔化',
    'Chemistry': '化学显影',
    'Glare': '眩光',
    'Preflashing': '预闪光',
    'Enlarger diffusion': '放大机柔化',
    'Spectral upsampling': '光谱上采样',
    'Input gamut compression': '输入色域压缩',
    'Output gamut compression': '输出色域压缩',
    'Tune': '微调',
    'Special': '特殊设置',
    'GUI parameters': '界面参数',
    'Display': '显示',
    'napari layers': 'napari 图层',
    'Select file': '选择文件',
    'Select input image': '选择输入图像',
    'Select input raw': '选择 RAW 文件',
    'No image selected': '未选择图像',
    'No raw selected': '未选择 RAW 文件',
    'reprocess raw': '重新处理 RAW',
    'Save current as default': '保存当前设置为默认值',
    'Save current to file': '将当前设置保存到文件',
    'Load from file': '从文件载入',
    'Restore factory default': '恢复出厂默认值',
    'Language': '界面语言',
    'Interface language': '选择界面显示语言。更改后重启应用生效。',
    'Language changed': '语言已更改',
    'Restart SpektraStudio to apply the new language.': '请重启 SpektraStudio 以应用新的界面语言。',
    'PREVIEW': '预览',
    'SCAN': '全尺寸处理',
    'SAVE': '保存',
    'update': '更新',
    'auto preview': '自动预览',
    'scan film': '扫描胶片',
    'scan for print': '按相纸扫描',
    'film profile': '胶片配置',
    'print profile': '相纸配置',
    'auto exposure': '自动曝光',
    'exposure compensation ev': '曝光补偿 EV',
    'print auto compensation': '相纸自动补偿',
    'print exposure': '相纸曝光',
    'print y filter shift': '黄色滤镜偏移',
    'print m filter shift': '品红滤镜偏移',
    'ccw rotate': '逆时针旋转',
    'cw rotate': '顺时针旋转',
    'reset view': '重置视图',
    'ready': '就绪',
    'active': '启用',
    'amount': '强度',
    'method': '方法',
    'strength': '强度',
    'size': '尺寸',
    'blur': '模糊',
    'radius': '半径',
    'temperature': '色温',
    'tint': '色调',
    'white balance': '白平衡',
    'lens correction': '镜头校正',
    'input color space': '输入色彩空间',
    'output color space': '输出色彩空间',
    'saving color space': '保存色彩空间',
    'use display transform': '使用显示器色彩转换',
    'gray 18 canvas': '18% 灰画布',
    'white padding': '白色边距',
    'output interpolation': '输出插值方式',
    'preview max size': '预览最大尺寸',
    'upscale factor': '放大倍数',
    'input cctf decoding': '输入 CCTF 解码',
    'rgb to raw method': 'RGB 转 RAW 方法',
    'film channel swap': '胶片通道交换',
    'print channel swap': '相纸通道交换',
    'film gamma factor': '胶片伽马系数',
    'print illuminant': '相纸照明光源',
    'saving cctf encoding': '保存时应用 CCTF 编码',
    'white correction': '白场校正',
    'black correction': '黑场校正',
    'unsharp mask': '反锐化蒙版',
    'unsharp mask radius': '反锐化半径',
    'unsharp mask strength': '反锐化强度',
    'diffusion size um': '扩散尺寸（微米）',
    'density curve gamma': '密度曲线伽马',
    'paper contrast': '相纸对比度',
    'preflash exposure': '预闪光曝光',
    'preflash y filter shift': '预闪光黄色滤镜偏移',
    'preflash m filter shift': '预闪光品红滤镜偏移',
    'Load raw': '载入 RAW',
    'Load raw failed': '载入 RAW 失败',
    'Loading raw...': '正在载入 RAW…',
    'Loaded raw': 'RAW 载入完成',
    'Loaded raw, lens correction not applied': 'RAW 载入完成，未应用镜头校正',
    'Save output': '保存输出',
    'Run simulation': '运行模拟',
    'Simulation already running': '模拟正在运行',
    'Load an input image before running the simulation.': '请先载入输入图像，再运行模拟。',
    'Run a simulation before saving the output layer.': '请先运行模拟，再保存输出图层。',
    'Simulation failed.': '模拟失败。',
    'Save GUI state': '保存界面状态',
    'Load GUI state': '载入界面状态',
    'Save current as default': '保存当前设置为默认值',
    'Restored factory default GUI state': '已恢复出厂默认界面设置',
    'Saved current GUI state as the startup default': '已将当前界面设置保存为启动默认值',
    'Display transform: disabled': '显示器色彩转换：已禁用',
    'Display transform: no display profile, using raw preview': '显示器色彩转换：未检测到显示配置文件，使用原始预览',
    'Display transform unavailable: no display profile detected, disabled': '显示器色彩转换不可用：未检测到显示配置文件，已禁用',
    'Pixel of the screen mapped 1 to 1 to the image pixel': '屏幕像素与图像像素按 1:1 显示',
    '2 screen pixels mapped to 1 image pixel': '2 个屏幕像素对应 1 个图像像素',
    '4 screen pixels mapped to 1 image pixel': '4 个屏幕像素对应 1 个图像像素',
    'Run the full simulation on the full-resolution input': '对全分辨率输入运行完整模拟',
    'Save the current output layer to an image file': '将当前输出图层保存为图像文件',
    'run the simulation on a small preview and deactivates grain, halation, blurs, unsharp mask (diffusion filters are active)': '在小尺寸预览上运行模拟，并关闭颗粒、光晕、模糊和反锐化蒙版（柔化滤镜仍启用）',
    'Load and process a raw file using rawpy, output colorspace and cctf as defined in current input widget state': '使用 rawpy 载入并处理 RAW 文件，输出色彩空间和 CCTF 由当前输入设置决定',
}

_WORD_ZH = {
    'film': '胶片', 'print': '相纸', 'camera': '相机', 'scanner': '扫描仪',
    'enlarger': '放大机', 'input': '输入', 'output': '输出', 'exposure': '曝光',
    'compensation': '补偿', 'profile': '配置', 'color': '色彩', 'space': '空间',
    'grain': '颗粒', 'halation': '光晕', 'glare': '眩光', 'diffusion': '柔化',
    'amount': '强度', 'strength': '强度', 'size': '尺寸', 'active': '启用',
    'gamma': '伽马', 'density': '密度', 'curve': '曲线', 'method': '方法',
    'scale': '比例', 'radius': '半径', 'blur': '模糊', 'mask': '蒙版',
    'white': '白色', 'black': '黑色', 'correction': '校正', 'temperature': '色温',
    'tint': '色调', 'illuminant': '照明光源', 'channel': '通道', 'swap': '交换',
    'auto': '自动', 'preview': '预览', 'saving': '保存', 'compression': '压缩',
    'gamut': '色域', 'threshold': '阈值', 'factor': '系数', 'weight': '权重',
    'interlayer': '层间', 'samelayer': '同层', 'scatter': '散射', 'tail': '尾部',
}


def language_settings() -> Any:
    return QtCore.QSettings(ORGANIZATION_NAME, APP_NAME)


def saved_language() -> str:
    value = str(language_settings().value('ui/language', LANGUAGE_ENGLISH))
    return value if value in LANGUAGE_LABELS else LANGUAGE_ENGLISH


def set_language(language: str, *, persist: bool = True) -> None:
    global _current_language
    _current_language = language if language in LANGUAGE_LABELS else LANGUAGE_ENGLISH
    if persist:
        language_settings().setValue('ui/language', _current_language)


def current_language() -> str:
    return _current_language


def _translate_generated_label(text: str) -> str:
    words = text.replace('_', ' ').split()
    if len(words) > 6 or any(re.search(r'[.!?:;]', word) for word in words):
        return text
    translated: list[str] = []
    for word in words:
        replacement = _WORD_ZH.get(word.lower())
        if replacement is None:
            return text
        translated.append(replacement)
    return ''.join(translated)


def tr(text: str) -> str:
    if _current_language != LANGUAGE_CHINESE or not text:
        return text
    if text in _ZH:
        return _ZH[text]
    lowered = text.lower()
    if lowered in _ZH:
        return _ZH[lowered]

    dynamic_patterns = (
        (r'^Computing (.+)\.\.\.$', lambda m: f'正在计算{tr(m.group(1))}…'),
        (r'^(.+) completed\. (.+)$', lambda m: f'{tr(m.group(1))}完成。{tr(m.group(2))}'),
        (r'^(.+) failed$', lambda m: f'{tr(m.group(1))}失败'),
        (r'^Saved output image to (.+)$', lambda m: f'输出图像已保存到 {m.group(1)}'),
        (r'^Saved GUI state to (.+)$', lambda m: f'界面状态已保存到 {m.group(1)}'),
        (r'^Loaded GUI state from (.+)$', lambda m: f'已从 {m.group(1)} 载入界面状态'),
        (r'^Display transform: display profile found \((.+)\)$', lambda m: f'显示器色彩转换：已找到显示配置文件（{m.group(1)}）'),
    )
    for pattern, formatter in dynamic_patterns:
        match = re.match(pattern, text)
        if match:
            return formatter(match)

    if re.fullmatch(r'[A-Za-z0-9_ /+().%-]+', text):
        return _translate_generated_label(text)
    return text


class TranslatedMessageBox:
    @staticmethod
    def critical(parent: Any, title: str, text: str, *args: Any, **kwargs: Any) -> Any:
        return QtWidgets.QMessageBox.critical(parent, tr(title), tr(text), *args, **kwargs)

    @staticmethod
    def warning(parent: Any, title: str, text: str, *args: Any, **kwargs: Any) -> Any:
        return QtWidgets.QMessageBox.warning(parent, tr(title), tr(text), *args, **kwargs)

    @staticmethod
    def information(parent: Any, title: str, text: str, *args: Any, **kwargs: Any) -> Any:
        return QtWidgets.QMessageBox.information(parent, tr(title), tr(text), *args, **kwargs)
