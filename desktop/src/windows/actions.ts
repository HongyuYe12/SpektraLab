// actions.ts — commands shared by the menu, the keys and the buttons.

import { tz } from '../i18n';
import { joinPath, platform } from '../platform';
import { host } from '../host/client';
import { applySettingsPreset, flushSave, openFolder, openPaths, pairComplete, sessionStore, setPages, setStatus } from '../state/session';
import { decodeSettingsPreset, encodeSettingsPreset, SETTINGS_PRESET_AREA, SETTINGS_PRESET_NAME } from '@shared/settingsPreset';
import { newSidecar } from '@shared/sidecar';

export async function openDialog() {
  if (sessionStore.getState().batchExporting) return;
  const dir = await platform().pickFolder(tz('Open a folder of photographs', '打开照片文件夹'));
  if (dir) await openFolder(dir);
}

export async function openFilesDialog() {
  if (sessionStore.getState().batchExporting) return;
  const files = await platform().pickFiles(tz('Open photographs', '打开照片'));
  if (files.length) await openPaths(files);
}

export async function revealSettings() {
  const sel = sessionStore.getState().selection;
  if (!sel) return;
  await flushSave();
  try {
    await platform().reveal(await platform().sidecarPath(sel));
  } catch {
    const p = await platform().appPaths();
    await platform().reveal(p.sidecars);
  }
}

export async function restartHost() {
  await host().restart();
}

export function openExport() {
  if (sessionStore.getState().selection && pairComplete()) setPages({ exportOpen: true });
}

export async function saveCurrentAsDefault() {
  const s = sessionStore.getState();
  if (!s.selection) return;
  try {
    await platform().storeWrite(SETTINGS_PRESET_AREA, SETTINGS_PRESET_NAME, encodeSettingsPreset(s.sidecar));
    setStatus(tz('Saved the current settings as the startup default.', '已将当前设置保存为启动默认值。'));
  } catch (e) {
    await platform().message('SpektraLab', tz(`Could not save the startup default.\n${String(e)}`, `无法保存启动默认值。\n${String(e)}`), 'error');
  }
}

export async function exportCurrentSettings() {
  const s = sessionStore.getState();
  if (!s.selection) return;
  const paths = await platform().appPaths();
  const path = await platform().pickSave(tz('Export settings', '导出设置'), joinPath(paths.pictures || paths.home, 'SpektraLab Settings.json'), 'json');
  if (!path) return;
  try {
    await platform().writeJson(path, encodeSettingsPreset(s.sidecar));
    setStatus(tz(`Exported settings to ${path}.`, `设置已导出到 ${path}。`));
  } catch (e) {
    await platform().message('SpektraLab', tz(`Could not export settings.\n${String(e)}`, `无法导出设置。\n${String(e)}`), 'error');
  }
}

export async function importSettings() {
  if (!sessionStore.getState().selection) return;
  const path = await platform().pickJson(tz('Import settings', '导入设置'));
  if (!path) return;
  try {
    const preset = decodeSettingsPreset(await platform().readJson(path));
    if (!preset) throw new Error(tz('This is not a supported SpektraLab settings file.', '这不是受支持的 SpektraLab 设置文件。'));
    if (applySettingsPreset(preset)) setStatus(tz(`Imported settings from ${path}.`, `已从 ${path} 导入设置。`));
  } catch (e) {
    await platform().message('SpektraLab', tz(`Could not import settings.\n${String(e)}`, `无法导入设置。\n${String(e)}`), 'error');
  }
}

export async function restoreFactoryDefault() {
  if (!sessionStore.getState().selection) return;
  if (!await platform().confirm(tz('Restore factory default', '恢复出厂默认值'),
    tz('Clear the saved startup default and reset all settings for the current photo?', '清除已保存的启动默认值，并重置当前照片的全部设置？'))) return;
  try {
    await platform().storeRemove(SETTINGS_PRESET_AREA, SETTINGS_PRESET_NAME);
    if (applySettingsPreset(newSidecar())) setStatus(tz('Restored the factory default.', '已恢复出厂默认值。'));
  } catch (e) {
    await platform().message('SpektraLab', tz(`Could not restore the factory default.\n${String(e)}`, `无法恢复出厂默认值。\n${String(e)}`), 'error');
  }
}
