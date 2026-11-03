from __future__ import annotations

import pytest

from spektrafilm_gui import i18n


@pytest.fixture(autouse=True)
def _use_english_ui_during_gui_tests():
    previous = i18n.current_language()
    i18n.set_language(i18n.LANGUAGE_ENGLISH, persist=False)
    try:
        yield
    finally:
        i18n.set_language(previous, persist=False)
