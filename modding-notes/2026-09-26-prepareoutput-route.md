# 2026-09-26 night — The finished-picture route, built (not run)

*Opus, `/pd`, home PC. The game was not launched and nothing here has been run.*

The rifle camera's own render target gets the picture before the game grades it (see the brightness note of the same day).
praydog's VR mod takes its second view from the view's last stage, PrepareOutput. So now we do too:

- a script word, `clonepo`, finds our camera's render stage and its PrepareOutput child and tells the plugin where it is;
- the plugin follows five pointers from there to the real graphics buffer, checking each step safely, and shows that buffer
  on the glass. It refuses anything that does not look like the same kind of buffer as the one it already shows.

The first pointer's position (+0xF8) is confirmed by REFramework's own log on every launch today; the other four come from
REFramework's source for this engine version and are not confirmed yet. The biggest unknown is whether that buffer still holds
our picture when the plugin reads it, or has been reused by then (praydog copies it earlier, during the draw).

The one-launch test and what each result means: `dev-archive/recon/2026-09-26p-prepareoutput-route/NEXT-RUN.md`.
