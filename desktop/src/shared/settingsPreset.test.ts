import { describe, expect, it } from 'vitest';
import { newSidecar } from './sidecar';
import { decodeSettingsPreset, encodeSettingsPreset } from './settingsPreset';
import { SCENE_LATITUDE_DEFAULT } from './params';

describe('settings presets', () => {
  it('round-trips editor settings without file-owned state', () => {
    const sidecar = structuredClone(newSidecar());
    sidecar.adjustments.exposure = 1.25;
    sidecar.decode.temperature = 6200;
    sidecar.geometry.quarterTurns = 1;
    sidecar.params.sceneLatitude.highlightPullBack = 2;
    sidecar.params.sceneLatitude.active = true;
    sidecar.params.sceneLatitude.highlightKnee = 4;
    sidecar.raw = { source: 'D:/photo.NEF', _spkRevision: 'secret', future: true };
    sidecar.solvedEV = 3;
    sidecar.state = 'processed';

    const encoded = encodeSettingsPreset(sidecar);
    const decoded = decodeSettingsPreset(encoded)!;

    expect(decoded.adjustments.exposure).toBe(1.25);
    expect(decoded.decode.temperature).toBe(6200);
    expect(decoded.geometry.quarterTurns).toBe(1);
    expect(decoded.params.sceneLatitude.highlightPullBack).toBe(2);
    expect(decoded.params.sceneLatitude.active).toBe(false);
    expect(decoded.params.sceneLatitude.highlightKnee).toBe(SCENE_LATITUDE_DEFAULT.highlightKnee);
    expect(decoded.raw).toEqual({});
    expect(decoded.solvedEV).toBeNull();
    expect(decoded.state).toBe('unprocessed');
    expect(JSON.stringify(encoded)).not.toContain('photo.NEF');
    expect(JSON.stringify(encoded)).not.toContain('secret');
  });

  it('refuses arbitrary JSON and unknown versions', () => {
    expect(decodeSettingsPreset({})).toBeNull();
    expect(decodeSettingsPreset({ format: 'SpektraLab Settings', version: 2, settings: {} })).toBeNull();
  });
});
