# getting started

Hello! This is a basic tutorial to get you started with Fewatsu.

## generating / creating fewatsu documents

It might be useful to actually have a document to display before you start implementing Fewatsu! To make one, you can either create one by hand (check out `FORMAT.md`), or you can try the experimental Markdown to Fewatsu converter in `/tools/md2fewatsu.py`.

## importing fewatsu

1. Snag the latest release of Fewatsu from the [releases page](https://github.com/Nanobot567/fewatsu/releases/latest) and extract the zip file.
2. Navigate to your Playdate project's `Source` directory.
3. Extract `fewatsu-lib.zip` to your project's libraries folder.
    - If you don't have one yet, I usually name my libraries folder `lib/` :P
4. Head over to your `main.lua`, or wherever you usually import libraries.
5. Add the line `import {LIBRARY_FOLDER}/fewatsu`.
6. Done!

## displaying fewatsu

First, initialize Fewatsu by placing this line in your code somewhere:

`fewatsu = Fewatsu:init()`

> (of course, the variable name can be something other than `fewatsu`)

By default, Fewatsu's current working directory is set to `manual/`, but it can be any folder you'd like. To change the folder, either set the current working directory in the init statement...

`fewatsu = Fewatsu:init({FOLDER_NAME_OR_PATH})`

...or set it with `Fewatsu:setCurrentWorkingDirectory()` after the init statement.

`fewatsu:setCurrentWorkingDirectory({FOLDER_NAME_OR_PATH})`

Then place all of your Fewatsu documents in this directory in your source code.

```
    Source/
    |
    |-- manual/
        |
        |-- doc1.json
        |-- doc2.json
```

Now, figure out when and where you'd like Fewatsu to be displayed. This could be after a button press, system menu item press, or a number of other things.

In the handler for this action, insert this line of code, where `DOCUMENT_FILENAME_OR_PATH` is a valid JSON file:

`fewatsu:loadFile({DOCUMENT_FILENAME_OR_PATH})`

This will load the file at that path if it is valid. If it's not, you'll likely run into an error when parsing. In this case, double check your `.json`!

> sidenote: you don't have to load your file here, you can do it anywhere before your `Fewatsu:show()` statement!

After this line, you can either display Fewatsu, or display it at a later time. To do this, simply insert:

`fewatsu:show()`

Fewatsu will then replace your pushed input handlers, `playdate.update()` function, and Playdate system menu buttons. You'll need to replace your system menu items manually with a callback, if you had any:

`fewatsu:setCallback({CALLBACK_FUNCTION})`

That's pretty much everything regarding the basics! If you're still confused, I recommend checking out the documentation and example (which can be found in this repository).
