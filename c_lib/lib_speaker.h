#ifndef __BOS_SPEAKER_H__
#define __BOS_SPEAKER_H__

#include "lib_bos_types.h"

void speaker_note(u8 octave, u8 note);
void speaker_play(u32 hz);
void speaker_off();


#endif
