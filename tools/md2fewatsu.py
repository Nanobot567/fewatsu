#!/bin/python3

# generates a new fewatsu document from preexisting markdown.

# supports:
# - headings (#, ##, ###)
# - quoteboxes (>)
# - images (![caption](link))
# - lists (-, 1.)
# - links ([text](page#section))
# - plaintext (anything else)

import argparse
import json
import pathlib
import re

fewatsuJSON = {
    "data": []
}

parser = argparse.ArgumentParser("md2fewatsu", description="convert a markdown document to fewatsu JSON")
parser.add_argument("markdown", help="markdown file", type=argparse.FileType())
parser.add_argument("-t", "--title", default=None, help="set title of Fewatsu page")
parser.add_argument("-o", "--output", default="output.json", help="write to file")
parser.add_argument("-p", "--pretty", default=False, action="store_true")

args = parser.parse_args()

f = args.markdown

lines = f.read().split("\n")
f.close()

outputFile = args.output

if args.title:
    fewatsuJSON["title"] = args.title
else:
    fewatsuJSON["title"] = pathlib.Path(args.markdown.name).stem

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

indent = None
if args.pretty:
    indent = 2

f.write(json.dumps(fewatsuJSON, indent=indent))
