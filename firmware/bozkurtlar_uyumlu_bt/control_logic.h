#pragma once
// Pure logic shared with the host-side test. Thresholds are raw ADC readings.
inline bool nextPumpState(bool current, int raw, bool rising, int on, int off) {
  if (!current && (rising ? raw >= on : raw <= on)) return true;
  if (current && (rising ? raw <= off : raw >= off)) return false;
  return current;
}
