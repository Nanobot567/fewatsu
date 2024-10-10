# fewatsu manual page format

`fewatsu` pages are just JSON files at their core. For it to be recognized by the library, a `fewatsu` JSON table must have two keys defined in the topmost object.

1. `"title"`: the displayed page name in the side menu
3. `"data"`: a JSON array containing all of the elements as objects.

Optionally, a third `"id"` key can be provided, which is the internal ID used to refer to the page when linking to it.

A valid `fewatsu` page may look like this:

```json
{
	"title":"Game Title",
	"id":"main",
	"data": [
		{
			"type": "title",
			"text": "Game Title"
		},
		{
			"type": "text",
			"text": "Here is some example text."
		}
	]
}
```

## built-in fewatsu elements

### global element notes and rules

- `fewatsu` element objects always should have the element name assigned to the `"type"` key, alongside the other required keys.
- any `fewatsu` element with a `"text"` key can display inline icons by surrounding the name of the icon in double square brackets (`[[` or `]]`). available icons are:
	- `a` (a button)
	- `b` (b button)
	- `up` (up button)
	- `down` (down button)
	- `left` (left button)
	- `right` (right button)
	- `dpad` (d-pad)
	- `playdate` (playdate console)
	- `menu` (menu button)
	- `lock` (lock button)
	- `crank` (crank)
- any path given can either be from the current working directory (set by either passing the directory into `Fewatsu:init()` or set by `Fewatsu:setCurrentWorkingDirectory()`) or a direct path.

### title
displays text in a large font. usually placed at the very beginning of the manual page. equivalent to a Markdown `#` or HTML `<h1>`.

- requires
	- `"text"`: the title's text (string)

### text
standard text element. inline text formatting (such as bold with `*` and italic with `_`) is possible.

- requires
	- `"text"`: displayed text (string)
- optional
	- `"x"`: x position of the rectangle to draw the text in (number)
	- `"y"`: y position of the rectangle to draw the text in (number)
	- `"width"`: width of the rectangle to draw the text in (number)
	- `"height"`: height of the rectangle to draw the text in (number)
	- `"alignment"`: text alignment within the rectangle (string ["left", "right", or "center"])

> tip: a shorthand for this is just using a string instead of an entire JSON object! for example:

```json
...
"data": [
	{
		"type": "title",
		"text": "Game Title"
	},
	"Here is some text!",
	"Here is another block of text!"
	...
]
```

### heading
heading element. equivalent to a Markdown `##` or HTML `<h2>`.

- requires
	- `"text"`: heading text (string)
- optional
	- `"alignment"`: text alignment (string ["left", "right", or "center"])

### subheading
subheading element. equivalent to a Markdown `###` or HTML `<h3>`.

- requires
	- `"text"`: subheading text (string)
- optional
	- `"alignment"`: text alignment (string ["left", "right", or "center"])

### image
image element. the image provided can either be a still image, or animated image (in `.pdt` format)

> note: left and right padding does not effect image position.
#### regular image
- requires
	- `"source"`: path to the image (string)
- optional
	- `"scale"`: image scale (number)
	- `"caption"`: image caption (string)
#### animated image
- requires
	- `"source"`: path to the animated image (string)
- optional
	- `"delay"`: the delay between each frame of the animated image (number)
	- `"scale"`: image scale (number)
		- note: it is recommended to not scale your animated images using this parameter, as it dramatically increases load times. instead, pre-scale your animated image using something like `imagemagick` or `aseprite`.

> note: please be aware of the Playdate's memory constraints when using animated images, as they can be large when loaded into RAM. if you plan on using a lot of animated images, consider splitting your manual into more pages, since animated images are unloaded when not in use.

### list
list element.

- requires
	- `"items"`: array of items (table of strings)
- optional
	- `"ordered"`: sets if the list should be ordered (1., 2., etc.) (boolean) (defaults to false)

### link
link to another document, or a part of the current document.

- requires
	- `"text"`: text to display (string)
	- and either / both:
		- `"page"`: ID of the page to jump to in the current working directory OR the path to the .json file (string)
		- `"section"`: name of the heading to jump to (string)

the `page` and `section` keys are case insensitive.

`section` can also be set to `#top` or `#bottom` to jump to those places.

### quote
quote box element, similar to HTML's `<blockquote>`.

- requires
	- `"text"`: the text to draw within the box (string)

### break
creates a line break in the page. equivalent to `<br>` or `<hr>` in HTML.

- optional
	- `"visible"`: defaults to true (boolean)
	- `"linewidth"`: the width of the line (number)

### qr
generates a qr code and inserts it into the document.

- requires
	- `"data"`: data to encode (string)
- optional
	- `"desiredEdgeDimension"`: desired edge dimension for the qr code (number)
	- `"alignment"`: alignment of the qr code in the document (string [left, right, or center])

> note: it is recommended to add a `text` or `quote` element that contains the contents of the qr code afterwards for readability.

> note: generating a QR code takes some time on device, and could possibly crash the device if the URL is too large. please consider pre-generating your QR codes.

## custom elements
Custom elements can be registered through `Fewatsu:registerCustomElement()`. The data table passed into this function must contain a few keys and their appropriate values.
### data format
- requires
	- `heightCalculationFunction`: this key should be set to a function which returns the height of the custom element. The element data table will be passed in as the first argument.
	- `drawFunction`: the function that draws the element to the screen. The element's y position in the viewing area will be provided as the first argument, the element data table will be provided as the second.
- optional
	- `padding`: the amount to pad the bottom of the element before the next element is drawn. If not provided, the default is `10` pixels.
	- `drawEveryFrame`: if true, will call `drawFunction` every frame where the element is visible.

### examples
#### basic custom element
```lua
local sineCustomElement = {
  heightCalculationFunction = function()
    return 100
  end,

  drawFunction = function(y, data)
    gfx.drawSineWave(0, y + 45, 400, y + 45, 35, 35, 50)
  end
}

fewatsu = Fewatsu()
fewatsu:registerCustomElement("sine", sineCustomElement)
```
#### dynamic custom element
```lua
-- file main.lua

local sineWavePhase = 0

local dynamicSineCustomElement = {
  heightCalculationFunction = function()
    return 100
  end,

  drawFunction = function(y, elementData)
    sineWavePhase += elementData["step"]

    if sineWavePhase >= 50 then
      sineWavePhase = 0
    end

    gfx.drawSineWave(0, y + 45, 420, y + 45, 35, 35, 50, -sineWavePhase)
  end,
  
  updateEveryFrame = true
}

fewatsu = Fewatsu()
fewatsu:registerCustomElement("dynamicSine", dynamicSineCustomElement)
```

```json
// file manual.json

{
	"title": "Main Page",
	"id": "main",
	"data": [
		...
		{
			"type": "dynamicSine",
		    "step": 2
		},
		...
	]
}
```
