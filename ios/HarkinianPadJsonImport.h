#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Opens Files to pick a JSON (randomizer spoiler or configuration) and hands it to the game as a dropped file.
void HarkinianPad_ImportJson(void);
// Draws the import button and its status (ImGui). id keeps several instances apart.
void HarkinianPad_DrawJsonImport(const char* id);

#ifdef __cplusplus
}
#endif
