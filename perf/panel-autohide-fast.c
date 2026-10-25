/* Shorten the auto-hide delays of xfce4-panel 4.20, which are hard-coded:
 *   popdown 350 ms, "slow" popdown x4 = 1400 ms (used when the pointer leaves), popup 225 ms,
 *   and a 25 ms step timer for the slide animation.
 * Only G_PRIORITY_LOW (300) timers are touched: those used by panel_window_autohide_queue() and the animation.
 * Loaded with LD_PRELOAD by the ~/.local/bin/xfce4-panel wrapper, for that process only. Measured: hide 1.8 s -> ~0.15 s. */
#define _GNU_SOURCE
#include <dlfcn.h>
typedef unsigned int guint; typedef int gint; typedef void *gpointer;
typedef int (*GSourceFunc)(gpointer); typedef void (*GDestroyNotify)(gpointer);
guint g_timeout_add_full(gint prio, guint ms, GSourceFunc f, gpointer d, GDestroyNotify n)
{
  static guint (*real)(gint, guint, GSourceFunc, gpointer, GDestroyNotify);
  if (!real) real = dlsym(RTLD_NEXT, "g_timeout_add_full");
  if (prio == 300) { if (ms == 1400) ms = 15; else if (ms == 350) ms = 15; else if (ms == 225) ms = 100; else if (ms == 25) ms = 6; }
  return real(prio, ms, f, d, n);
}
