# Softcut Notes

## Buffer System

Softcut provides a flexible sample playback system with the following components:

### Buffers
- 2 stereo buffers available (buffers 1 and 2)
- Each buffer can store one complete sample
- Buffers persist in memory until cleared
- Loading a new sample into a buffer overwrites the previous sample

### Buffer Capacity and Format
- Each buffer is stereo (2 channels)
- Total buffer capacity is approximately 5 minutes of stereo audio at 48kHz
- This capacity is shared between both buffers
- Mono samples can be loaded into either the left or right channel of a buffer
- This means you can effectively have up to 4 different mono samples loaded:
  - Buffer 1 Left: Mono Sample A
  - Buffer 1 Right: Mono Sample B
  - Buffer 2 Left: Mono Sample C
  - Buffer 2 Right: Mono Sample D
- Voices can be assigned to read from either the left or right channel of their assigned buffer
- This effectively allows for 4 different sample sources with the 6 voices

### Voices
- 6 independent voices available
- Each voice can be assigned to read from either buffer 1 or buffer 2
- Each voice can be assigned to read from either the left or right channel of its buffer
- Multiple voices can read from the same buffer/channel simultaneously
- Each voice can have independent:
  - Playback position
  - Playback rate
  - Volume level
  - Pan position
  - Loop points

### Playback Possibilities
While limited to two different samples at once (one in each buffer), the system allows for complex playback scenarios:

1. **Single Sample Playback**
   - All 6 voices can play from buffer 1
   - Each voice can play different parts of the same sample
   - Different playback parameters for each voice

2. **Dual Sample Playback**
   - Some voices can play from buffer 1
   - Other voices can play from buffer 2
   - Any combination of voices between the two buffers

3. **Quad Mono Sample Playback**
   ```
   Buffer 1 Left:  Mono Sample A
   Buffer 1 Right: Mono Sample B
   Buffer 2 Left:  Mono Sample C
   Buffer 2 Right: Mono Sample D
   
   Voice 1: Playing from Buffer 1 Left  (Sample A)
   Voice 2: Playing from Buffer 1 Right (Sample B)
   Voice 3: Playing from Buffer 2 Left  (Sample C)
   Voice 4: Playing from Buffer 2 Right (Sample D)
   Voice 5: Playing from Buffer 1 Left  (Sample A)
   Voice 6: Playing from Buffer 2 Right (Sample D)
   ```

### Key Limitations
- Maximum of 2 different stereo samples loaded at once
- Maximum of 4 different mono samples loaded at once (2 per buffer)
- Total buffer capacity is shared between both buffers
- Buffer size is fixed at approximately 5 minutes of stereo audio at 48kHz

### Best Practices
- Clear buffers before loading new samples
- Consider buffer management when designing sample switching logic
- Use voice parameters to create variety when limited to two samples
- Plan sample selection to maximize the potential of the two-buffer system
- Consider using mono samples in separate channels to effectively double the number of available samples
- Be mindful of total buffer capacity when loading long samples 