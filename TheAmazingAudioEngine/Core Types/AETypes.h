//
//  AETypes.h
//  TheAmazingAudioEngine
//
//  Created by Michael Tyson on 23/03/2016.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

@import Foundation;
@import AudioToolbox;

#ifdef __cplusplus
extern "C" {
#endif

/*!
 * The audio description used throughout TAAE
 *
 *  This is 32-bit floating-point, non-interleaved stereo PCM.
 */
extern const AudioStreamBasicDescription AEAudioDescription;

/*!
 * Get the TAAE audio description at a given sample rate
 *
 * @param channels Number of channels
 * @param rate The sample rate
 * @return The audio description
 */
AudioStreamBasicDescription AEAudioDescriptionWithChannelsAndRate(int channels, double rate);

/*!
 * File types
 */
typedef enum {
    AEAudioFileTypeAIFFFloat32, //!< 32-bit floating point AIFF (AIFC)
    AEAudioFileTypeAIFFInt16,   //!< 16-bit signed little-endian integer AIFF
    AEAudioFileTypeM4A,         //!< AAC in an M4A container
} AEAudioFileType;

/*!
 * Channel set
 */
typedef struct {
    int firstChannel; //!< The index of the first channel of the set
    int lastChannel;  //!< The index of the last channel of the set
} AEChannelSet;
    
extern AEChannelSet AEChannelSetDefault; //!< A default, stereo channel set

/*!
 * Create an AEChannelSet
 *
 * @param firstChannel The first channel
 * @param lastChannel The last channel
 * @returns An initialized AEChannelSet structure
 */
static inline AEChannelSet AEChannelSetMake(int firstChannel, int lastChannel) {
    return (AEChannelSet) {firstChannel, lastChannel};
}

#ifdef __cplusplus
}
#endif
