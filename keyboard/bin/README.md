`keyd-application-mapper` is a copy of the script shipped with [keyd](https://github.com/rvaiya/keyd) (MIT)
with two changes, marked `mac-keyboard` in the file:

1. it no longer walks every X window on every event (one X request per window);
2. it only re-applies the rules when they actually change. Stock behaviour resets them on every window
   *title* change, which loops forever in a terminal whose title changes (6-8 % CPU, delayed shortcuts).
