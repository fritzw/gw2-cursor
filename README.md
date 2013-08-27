GW2-Cursor
==========

I got tired of losing my mouse pointer in particle fireworks in the heat of the battle in Guild Wars 2. So I wrote this small script to make the mouse cursor more visible:

![Without overlay][withoutOverlay]

![With overlay][withOverlay]

It's written in [AutoIt3](http://www.autoitscript.com/), a scripting language for Windows automation. There's is also a [standalone version](#standalone-version) so you don't need to install AutoIt3 to use it.

Look at the file `settings-example.ini` for some configuration options and examples for adding your own cursor.



How does it work?
-----------------

Basically the black cursor you see is just a semi-transparent, arrow-shaped, click-through window that moves around with your mouse pointer. The script simply checks the mouse position 120 times per second (twice the screen refresh rate) and then moves the overlay to where your mouse is.

This approach has the limitation that there is a slight delay. So when you move your mouse, the overlay cursor will always lag behind the real cursor a bit. You need to decide for yourself if this annoys you or not. For me it's okay because the overlay is very visible while the default cursor is nearly invisible when you move it quickly, so I only see the overlay anyways.

**Note:** Since the cursor is just a window, it will **not** be visible in fullscreen mode, where all windows are hidden. You need to run the game in **windowed mode** or **windowed fullscreen mode** to see the cursor.


How can I download and install it?
----------------------------------

Installation isn't necessary. The script writes only in the directory where you put it, and when you delete it, it's gone.

For downloading you basically have 3 options:

* Download the [standalone `.exe` file](https://github.com/fritzw/gw2-cursor/raw/master/gw2cursor.exe). Just put it in a folder and run it.
* Download the [whole repository as a zip file](https://github.com/fritzw/gw2-cursor/archive/master.zip) and run `gw2cursor.au3`. You need AutoIt3 installed for this to work, but you can view and change the source code.
 * Technically you only need the following files: `gw2cursor.au3`, `Serialize.au3`, `cursor1.png`, `tray-icon.ico` (optional)
* Clone the repository.


Can I get banned for using it?
------------------------------

From a technical perspective the answer is _"probably not"_ because it's just a another window moving around on your screen that doesn't interact with Guild Wars 2 at all. It doesn't even intercept mouse clicks or anything like that, it's just completely transparent to mouse events.

While I think it's nonsense, I think should still let you know what another player said about it in the game: _"Well, it clearly gives you an advantage over other players when you don't lose your mouse pointer in battles, so it's not allowed"_.

Note that the above is also true for the [Combat Mode Script](http://www.reddit.com/r/Guildwars2/comments/10s4s6/combat_mode_11/), which shows a crosshair in the center of the screen in the same way as the cursor overlay. I haven't heard of anyone getting banned for using that.


How can I contact you?
----------------------

Just send an in-game mail to Baumkeks. Or you could contact me [on Reddit](http://www.reddit.com/user/blamestar/).

[withoutOverlay]: https://raw.github.com/fritzw/gw2-cursor/master/screenshot1.jpg "Without overlay: Cursor in stealth mode"
[withOverlay]: https://raw.github.com/fritzw/gw2-cursor/master/screenshot2.jpg "With overlay: Cursor visible"
