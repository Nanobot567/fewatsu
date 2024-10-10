# fewatsu api

<details>
<summary>Table of Contents</summary>
<br>
[addMenuItem](#addMenuItem)

[clearAnimatedImageCache](#clearAnimatedImageCache)

[getCurrentWorkingDirectory](#getCurrentWorkingDirectory)

[hide](#hide)

[init](#init)

[load](#load)

[loadFile](#loadFile)

[registerCustomElement](#registerCustomElement)

[setBGM](#setBGM)

[setBGMFade](#setBGMFade)

[setBGMVolume](#setBGMVolume)

[setBoldFont](#setBoldFont)

[setCallback](#setCallback)

[setClickSound](#setClickSound)

[setCurrentWorkingDirectory](#setCurrentWorkingDirectory)

[setDarkMode](#setDarkMode)

[setEnableBGM](#setEnableBGM)

[setEnableLoadingScreen](#setEnableLoadingScreen)

[setEnableSFX](#setEnableSFX)

[setEnableScrollBar](#setEnableScrollBar)

[setFont](#setFont)

[setHeadingFont](#setHeadingFont)

[setItalicFont](#setItalicFont)

[setLeftPadding](#setLeftPadding)

[setLinkFont](#setLinkFont)

[setLoadingScreenShowPercent](#setLoadingScreenShowPercent)

[setLoadingScreenShowSpinner](#setLoadingScreenShowSpinner)

[setLoadingScreenShowText](#setLoadingScreenShowText)

[setLoadingScreenTextAlignment](#setLoadingScreenTextAlignment)

[setMenuAutoAdd](#setMenuAutoAdd)

[setMenuEaseDuration](#setMenuEaseDuration)

[setMenuEasingFunction](#setMenuEasingFunction)

[setMenuSound](#setMenuSound)

[setMenuTitle](#setMenuTitle)

[setMenuWidth](#setMenuWidth)

[setPadding](#setPadding)

[setPostUpdate](#setPostUpdate)

[setPreUpdate](#setPreUpdate)

[setQuoteBoxPadding](#setQuoteBoxPadding)

[setRightPadding](#setRightPadding)

[setScrollBarBackgroundImage](#setScrollBarBackgroundImage)

[setScrollBarImage](#setScrollBarImage)

[setScrollBarTimeout](#setScrollBarTimeout)

[setScrollDuration](#setScrollDuration)

[setScrollEasingFunction](#setScrollEasingFunction)

[setSelectSound](#setSelectSound)

[setShowSplash](#setShowSplash)

[setSplashBackground](#setSplashBackground)

[setSplashFont](#setSplashFont)

[setSplashText](#setSplashText)

[setSubheadingFont](#setSubheadingFont)

[setTitleFont](#setTitleFont)

[setTopPadding](#setTopPadding)

[show](#show)

[update](#update)

</details>

## Fewatsu
### addMenuItem
```lua
    (method) Fewatsu:addMenuItem(path: string, displayName?: string)
    -> nil
```
Adds a page to the Fewatsu menu. `:setMenuAutoAdd()` must be `true`.

`path` can be either an absolute path to the file or the path from Fewatsu's current working directory. Looks for [path], then [path].json.

`displayName` can be provided if you would like the item to have a different display name than the default (the page's title).

### clearAnimatedImageCache
```lua
    (method) Fewatsu:clearAnimatedImageCache()
    -> nil
```
Clears the Fewatsu animated image cache.

### getCurrentWorkingDirectory
```lua
    (method) Fewatsu:getCurrentWorkingDirectory()
    -> string
```
Returns the current working directory.

### hide
```lua
    (method) Fewatsu:hide(preserveCache: boolean)
    -> nil
```
Hides Fewatsu, restoring the original `playdate.update()` function and input handlers.

If `preserveCache` is `true`, doesn't clear the animated image and QR code caches.

The current Fewatsu document and state are preserved.

### init
```lua
    (method) Fewatsu:init(workingDirectory?: string)
    -> Fewatsu
```
Initializes a new Fewatsu instance at `workingDirectory` and loads the default document.

Default path is `manual/`.

### load
```lua
    (method) Fewatsu:load(data: table)
    -> playdate.image
```
Parses the given table (if valid) and sets the current manual page to the image generated. Refer to the Fewatsu FORMAT.md doc for more information.

### loadFile
```lua
    (method) Fewatsu:loadFile(path: string)
    -> playdate.graphics.image
```
Shorthand function for loading a JSON file into Fewatsu.

`path` can be an absolute path or a path from the current working directory.

File extension can be omitted (will check for `.json` files).

Returns the generated image.

### registerCustomElement
```lua
    (method) Fewatsu:registerCustomElement(name: string, data: table)
    -> nil
```
Registers a new custom element.

Please see the `custom elements` section in the Fewatsu format documentation (`FORMAT.md`) for more information.

### setBGM
```lua
    (method) Fewatsu:setBGM(sound: playdate.sound.fileplayer)
    -> nil
```
Sets the background music that will play while Fewatsu is active.

By default uses the file `FEWATSU_LIB_PATH/snd/bgm`.

### setBGMFade
```lua
    (method) Fewatsu:setBGMFade(fadetime: number)
    -> nil
```
Sets the background music fade in/out time in seconds.

Defaults to `1` second.

### setBGMVolume
```lua
    (method) Fewatsu:setBGMVolume(volume: number)
    -> nil
```
Sets the background music volume.

Defaults to `0.2`.

### setBoldFont
```lua
    (method) Fewatsu:setBoldFont(font: playdate.graphics.font)
    -> nil
```
Sets the font used for bold text.

### setCallback
```lua
    (method) Fewatsu:setCallback(callback: function)
    -> nil
```
Sets the function to be called when Fewatsu has completed its `:hide()` function.

### setClickSound
```lua
    (method) Fewatsu:setClickSound(sound: playdate.sound.sampleplayer)
    -> nil
```
Sets the sound that will be played when the A button is pressed.

### setCurrentWorkingDirectory
```lua
    (method) Fewatsu:setCurrentWorkingDirectory(dir: string)
    -> boolean
```
Sets the current working directory. Fewatsu can use this to call for images and JSON files without using the absolute path.

By default, the working directory is set to `/manual/`.

Returns `true` on success, `false` on failure.

### setDarkMode
```lua
    (method) Fewatsu:setDarkMode(mode: boolean)
    -> nil
```
Set if dark theme should be used. Doesn't apply to images, and is only applied on `:load()`.

Defaults to `false`.

### setEnableBGM
```lua
    (method) Fewatsu:setEnableBGM(status: boolean)
    -> nil
```
Enables or disables background music.

Defaults to `true`.

### setEnableLoadingScreen
```lua
    (method) Fewatsu:setEnableLoadingScreen(enable: boolean)
    -> nil
```
Sets if a loading screen should be displayed on document load and Fewatsu is currently shown.

Please note that this reduces load times.

Defaults to `true`.

### setEnableSFX
```lua
    (method) Fewatsu:setEnableSFX(status: boolean)
    -> nil
```
Sets if sound effects should play on user interaction (A button press, B button press, crank, etc)

Defaults to `true`.

### setEnableScrollBar
```lua
    (method) Fewatsu:setEnableScrollBar(enable: boolean)
    -> nil
```
Sets if the scroll bar should be displayed when the user scrolls through the Fewatsu document.

See `:setScrollBarBackgroundImage()` and `:setScrollBarImage()` to customize the scroll bar.

Defaults to `true`.

### setFont
```lua
    (method) Fewatsu:setFont(font: playdate.graphics.font)
    -> nil
```
Sets the font used for plaintext.

### setHeadingFont
```lua
    (method) Fewatsu:setHeadingFont(font: playdate.graphics.font)
    -> nil
```
Sets the font used for heading text.

### setItalicFont
```lua
    (method) Fewatsu:setItalicFont(font: playdate.graphics.font)
    -> nil
```
Sets the font used for italic text.

### setLeftPadding
```lua
    (method) Fewatsu:setLeftPadding(px: number)
    -> nil
```
Sets the pixel amount to pad the left side of the Fewatsu viewing area.

Defaults to `4`px.

### setLinkFont
```lua
    (method) Fewatsu:setLinkFont(font: playdate.graphics.font)
    -> nil
```
Sets the font used for link text.

### setLoadingScreenShowPercent
```lua
    (method) Fewatsu:setLoadingScreenShowPercent(show: boolean)
    -> nil
```
Sets if loading screens should display the percent complete alongside the text.

The loading screen must be enabled for this to take effect. See `:setEnableLoadingScreen()` for more details.

Loading screen text must be enabled for this to take effect. See `:setLoadingScreenShowText()` for more details.

Defaults to `true`.

### setLoadingScreenShowSpinner
```lua
    (method) Fewatsu:setLoadingScreenShowSpinner(show: boolean)
    -> nil
```
Sets if loading screens should display a spinner in the center of the screen.

The loading screen must be enabled for this to take effect. See `:setEnableLoadingScreen()` for more details.

Defaults to `true`.

### setLoadingScreenShowText
```lua
    (method) Fewatsu:setLoadingScreenShowText(show: boolean)
    -> nil
```
Sets if loading screens should display text detailing the current action on the bottom of the screen.

The loading screen must be enabled for this to take effect. See `:setEnableLoadingScreen()` for more details.

Defaults to `true`.

### setLoadingScreenTextAlignment
```lua
    (method) Fewatsu:setLoadingScreenTextAlignment(alignment: integer)
    -> nil
```
Sets how the loading screen bottom information text should be aligned. Can be any `kTextAlignment` or integer from 0 to 2.

The loading screen must be enabled for this to take effect. See `:setEnableLoadingScreen()` for more details.

Loading screen text must be enabled for this to take effect. See `:setLoadingScreenShowText()` for more details.

Defaults to `kTextAlignment.right`.

### setMenuAutoAdd
```lua
    (method) Fewatsu:setMenuAutoAdd(enable: boolean)
    -> nil
```
Enables or disables the automatic adding of pages to the Fewatsu menu.

By default, the menu will add all of the valid Fewatsu JSON files in the current working directory.

To customize the menu manually, see `:addMenuItem()`, `:removeMenuItem()` and `:clearMenuItems()`.

### setMenuEaseDuration
```lua
    (method) Fewatsu:setMenuEaseDuration(ms: number)
    -> nil
```
Sets the time it takes for the menu to ease in.

Defaults to `350`ms.

### setMenuEasingFunction
```lua
    (method) Fewatsu:setMenuEasingFunction(func: function)
    -> nil
```
Sets a different easing function which will be used instead of the default when animating the menu slide-in. Can be any `playdate.easingFunction`.

Defaults to `playdate.easingFunctions.outExpo`.

### setMenuSound
```lua
    (method) Fewatsu:setMenuSound(sound: playdate.sound.sampleplayer)
    -> nil
```
Sets the sound that will be played when the Fewatsu menu is opened or closed.

### setMenuTitle
```lua
    (method) Fewatsu:setMenuTitle(title: string)
    -> nil
```
Sets the text shown at the top of the menu.

Defaults to `Fewatsu`.

### setMenuWidth
```lua
    (method) Fewatsu:setMenuWidth(width: number)
    -> nil
```
Sets the menu width.

Defaults to `120`px.

### setPadding
```lua
    (method) Fewatsu:setPadding(px: number)
    -> nil
```
Sets the amount to pad both sides of the Fewatsu document.

Shorthand function for `:setLeftPadding()` and `:setRightPadding()`.

Defaults to `4`px.

### setPostUpdate
```lua
    (method) Fewatsu:setPostUpdate(func: function)
    -> nil
```
Sets the function that is called after all processing in `:update()`.

### setPreUpdate
```lua
    (method) Fewatsu:setPreUpdate(func: function)
    -> nil
```
Sets the function that is called before any processing happens in `:update()`.

### setQuoteBoxPadding
```lua
    (method) Fewatsu:setQuoteBoxPadding(px: number)
    -> nil
```
Sets the pixel amount to pad the right and left side of quote boxes.

Defaults to `30`px.

### setRightPadding
```lua
    (method) Fewatsu:setRightPadding(px: number)
    -> nil
```
Sets the pixel amount to pad the right side of the Fewatsu viewing area.

Defaults to `4`px.

### setScrollBarBackgroundImage
```lua
    (method) Fewatsu:setScrollBarBackgroundImage(image: playdate.graphics.image)
    -> nil
```
Sets the image to use for the scroll bar background.

The image should be 20 pixels wide and 240 pixels tall.

### setScrollBarImage
```lua
    (method) Fewatsu:setScrollBarImage(image: playdate.graphics.image)
    -> nil
```
Sets the image to use for the scroll bar.

The image should be 20 pixels wide, and up to 160 pixels tall. For the best results, it is recommended to add two or so pixels of padding to every side of the image.

### setScrollBarTimeout
```lua
    (method) Fewatsu:setScrollBarTimeout(ms: any)
    -> nil
```
Sets the amount of time after user input has stopped to retract the scroll bar.

Defaults to `750`ms.

### setScrollDuration
```lua
    (method) Fewatsu:setScrollDuration(ms: number)
    -> nil
```
Sets the time it takes to scroll to a new manual page offset.

Defaults to `400`ms.

### setScrollEasingFunction
```lua
    (method) Fewatsu:setScrollEasingFunction(func: function)
    -> nil
```
Sets a different easing function which will be used instead of the default when scrolling to a new manual page offset. Can be any `playdate.easingFunction`.

Defaults to `playdate.easingFunctions.outExpo`.

### setSelectSound
```lua
    (method) Fewatsu:setSelectSound(sound: playdate.sound.sampleplayer)
    -> nil
```
Sets the sound that will be played in the Fewatsu menu when `up` or `down` is pressed.

### setShowSplash
```lua
    (method) Fewatsu:setShowSplash(show: boolean)
    -> nil
```
Set if a splash screen should be displayed when `:show()` is called.

Defaults to `true`.

### setSplashBackground
```lua
    (method) Fewatsu:setSplashBackground(bg: playdate.graphics.image)
    -> nil
```
Sets the splash screen background.

Requires that `:setShowSplash()` has been set to true.

By default, shows the latest Fewatsu frame.

`bg` image size must be 400 x 240 pixels.

### setSplashFont
```lua
    (method) Fewatsu:setSplashFont(font: playdate.graphics.font)
    -> nil
```
Sets the splash screen font.

Requires that `:setShowSplash()` has been set to true.

### setSplashText
```lua
    (method) Fewatsu:setSplashText(text: string)
    -> nil
```
Sets the splash screen text.

Requires that `:setShowSplash()` has been set to true.

Defaults to `Fewatsu`.

### setSubheadingFont
```lua
    (method) Fewatsu:setSubheadingFont(font: playdate.graphics.font)
    -> nil
```
Sets the font used for subheading text.

### setTitleFont
```lua
    (method) Fewatsu:setTitleFont(font: playdate.graphics.font)
    -> nil
```
Sets the font used for title text.

### setTopPadding
```lua
    (method) Fewatsu:setTopPadding(px: number)
    -> nil
```
Sets the amount to pad the top of the Fewatsu document.

Defaults to `4`px.

### show
```lua
    (method) Fewatsu:show(callback: function)
    -> nil
```
Displays Fewatsu.

Executing this function replaces the current `playdate.update` function, pushes new input handlers, and changes the display refresh rate. To restore, call `:hide()`.

All `playdate.menu` items will also be cleared. To restore these, set a callback function using `:setCallback()` containing instructions to restore the previous menu items.

`callback` can be provided if you would like an action to be performed after Fewatsu's splash screen has finished displaying (or, if you have it disabled, immediately after Fewatsu finishes its `show()` function).

### update
```lua
    (method) Fewatsu:update(force: boolean)
    -> nil
```
Updates Fewatsu and draws it to the screen if needed.

If `force` is true, draw to the screen regardless of status.

You shouldn't have to call this at all yourself. If you're looking to display Fewatsu, see `:show()`.

