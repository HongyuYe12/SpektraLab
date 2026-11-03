from __future__ import annotations

from spektrafilm_gui import i18n


class _MemorySettings:
    def __init__(self, values: dict[str, str] | None = None) -> None:
        self.values = dict(values or {})

    def value(self, key: str, default: str) -> str:
        return self.values.get(key, default)

    def setValue(self, key: str, value: str) -> None:  # noqa: N802 - Qt API name
        self.values[key] = value


def test_english_is_the_safe_default(monkeypatch) -> None:
    settings = _MemorySettings({'ui/language': 'unsupported'})
    monkeypatch.setattr(i18n, 'language_settings', lambda: settings)

    assert i18n.saved_language() == i18n.LANGUAGE_ENGLISH


def test_chinese_translates_fixed_generated_and_dynamic_text() -> None:
    previous = i18n.current_language()
    try:
        i18n.set_language(i18n.LANGUAGE_CHINESE, persist=False)

        assert i18n.tr('FILM') == '胶片'
        assert i18n.tr('grain radius') == '颗粒半径'
        assert i18n.tr('Saved output image to C:/output.tif') == '输出图像已保存到 C:/output.tif'
        assert i18n.tr('Kodak Portra 400') == 'Kodak Portra 400'
        assert i18n.tr('ACES2065-1') == 'ACES2065-1'
    finally:
        i18n.set_language(previous, persist=False)


def test_language_selection_is_persisted(monkeypatch) -> None:
    settings = _MemorySettings()
    monkeypatch.setattr(i18n, 'language_settings', lambda: settings)
    previous = i18n.current_language()
    try:
        i18n.set_language(i18n.LANGUAGE_CHINESE)

        assert settings.values['ui/language'] == i18n.LANGUAGE_CHINESE
    finally:
        i18n.set_language(previous, persist=False)
