# Dasko AI sound assets

- `welcome.wav`: short locally bundled startup chime, played through
  `audioplayers`.
- The exact Arabic greeting `أهلاً بك يا داسكو.` is spoken using the device's
  Arabic text-to-speech voice through `flutter_tts`.

Android speech output depends on a compatible Arabic TTS voice being installed
and enabled on the device. If no voice is available, the app still opens and
the local chime remains independent of speech.
