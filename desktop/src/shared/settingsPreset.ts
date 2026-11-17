import { placementIntent } from './latitude.ts';
import { decodeSidecar, encodeSidecar, type Sidecar } from './sidecar.ts';

export const SETTINGS_PRESET_AREA = 'Defaults';
export const SETTINGS_PRESET_NAME = 'editor.json';

export interface SettingsPreset {
  format: 'SpektraLab Settings';
  version: 1;
  settings: Record<string, unknown>;
}

/** A portable editor setup, without file identity, solved values or save tokens. */
export function encodeSettingsPreset(sidecar: Sidecar): SettingsPreset {
  const settings = encodeSidecar({
    ...sidecar,
    raw: {},
    solvedEV: null,
    state: 'unprocessed',
    params: { ...sidecar.params, sceneLatitude: placementIntent(sidecar.params.sceneLatitude) },
  });
  delete settings.source;
  delete settings._spkRevision;
  return { format: 'SpektraLab Settings', version: 1, settings };
}

/** Returns null for unrelated JSON so an accidental import cannot alter a frame. */
export function decodeSettingsPreset(raw: unknown): Sidecar | null {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const value = raw as Partial<SettingsPreset>;
  if (value.format !== 'SpektraLab Settings' || value.version !== 1 || !value.settings || typeof value.settings !== 'object') return null;
  const decoded = decodeSidecar(value.settings);
  return {
    ...decoded,
    raw: {},
    solvedEV: null,
    state: 'unprocessed',
    params: { ...decoded.params, sceneLatitude: placementIntent(decoded.params.sceneLatitude) },
  };
}
