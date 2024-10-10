#!/bin/python3

# generates a new fewatsu document from preexisting markdown.

# supports:
# - headings (#, ##, ###)
# - quoteboxes (>)
# - images (![caption](link))
# - lists (-, 1.)
# - links ([text](page#section))
# - plaintext (anything else)

import json
import re
import sys

outputFile = "output.json"

fewatsuJSON = {
    "data": []
}

if "--help" in sys.argv or "-h" in sys.argv or len(sys.argv) == 1:
    print("usage: python3 md2fewatsu.py [OPTION]... markdown.md\nconvert a markdown document to fewatsu JSON.")

    print("\narguments (these require a name afterwards):")
    print("\t-t, --title    set title of Fewatsu page")
    print("\t-o, --output   write to file\n")
    quit()

sys.argv.pop(0)

index = 0

while (index < len(sys.argv)):
    a = sys.argv[index]
    if a == "-t" or a == "--title":
        try:
            fewatsuJSON["title"] = sys.argv[index + 1]

            sys.argv.pop(index)
            sys.argv.pop(index)
            index -= 2
        except IndexError:
            print("ERROR: -t requires that a name be provided!")
            quit()
    elif a == "-o" or a == "--output":
        try:
            outputFile = sys.argv[index + 1]

            sys.argv.pop(index)

            sys.argv.pop(index)
            index -= 2
        except IndexError:
            print("ERROR: -o requires that a name be provided!")
            quit()

    index += 1

try:
    f = open(sys.argv[-1], "r")
except FileNotFoundError:
    print("ERROR: file " + sys.argv[-1] + " not found!")
    quit()
except IndexError:
    print("ERROR: file name / path must be provided!")
    quit()

lines = f.read().split("\n")
f.close()

lineIndex = 0

while lineIndex != len(lines):
    line = lines[lineIndex]
    temp = {}

    if line:
        line.replace("\t", "    ")

        if line.startswith("###"):
            temp["type"] = "subheading"
            temp["text"] = line[3:].strip("#").strip()
        elif line.startswith("##"):
            temp["type"] = "heading"
            temp["text"] = line[2:].strip()
        elif line.startswith("#"):
            temp["type"] = "title"
            temp["text"] = line[1:].strip()
        elif line.startswith(">"):
            temp["type"] = "quote"
            temp["text"] = line[1:].strip()
        elif line.startswith("!"):
            caption = line.split("[")[1].split("]")[0]

            if caption:
                temp["caption"] = caption

            temp["type"] = "image"
            temp["source"] = line.split("]")[1][1:].split(r".")[0].rstrip(")")
        elif line.strip().startswith("-"):
            ulist = []

            while line.strip().startswith("-"):
                ulist.append("".join(line.split("-")[1:]).strip())
                lineIndex += 1
                line = lines[lineIndex]

            temp["type"] = "list"
            temp["items"] = ulist
        elif "." in line and line.split(r".")[0].isdigit():
            olist = []

            while line.split(r".")[0].isdigit():
                olist.append("".join(line.split(r".")[1:]).strip())
                lineIndex += 1
                line = lines[lineIndex]

            temp["type"] = "list"
            temp["items"] = olist
            temp["ordered"] = True
        elif line.strip().startswith("[") or line.strip().startswith("("):
            t = re.search(re.compile(r"(?!\[).*(?=\])"), line)

            if t:
                temp["text"] = t.group(0)
            else:
                temp["text"] = ""

            temp["type"] = "link"
            
            inlink = re.search(re.compile(r"(?<=\().*(?=\))"), line).group(0)

            temp["page"] = inlink.split("#")[0]

            if "#" in inlink:
                temp["section"] = inlink.split("#")[1]
        else:
            temp = line
            
        fewatsuJSON["data"].append(temp)

    lineIndex += 1

f = open(outputFile, "w+")


f.write(json.dumps(fewatsuJSON))
