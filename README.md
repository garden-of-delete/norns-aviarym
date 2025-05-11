# AVIARYM

A norns script

### Utils
Convert directory of mp3 samples to 48kHz, 16-bit, mono WAV
```
for file in *.mp3; do ffmpeg -i "$file" -ar 48000 -ac 1 -acodec pcm_s16le "${file%.mp3}.wav"; done
```