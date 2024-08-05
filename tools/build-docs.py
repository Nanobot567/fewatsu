# builds documentation as a markdown file from src/lib/fewatsu.lua
# be sure to cd into tools/ first!

markdownFile = open("../GENERATED_DOCS.md", "w+")
markdownFile.write("# fewatsu documentation\n\n## Fewatsu\n\n")

with open("../src/lib/fewatsu.lua") as f:
    content = f.read()


lastLineWasPrefix = False

functions = {}

functionMeta = {"description": [], "params": [], "return": []}

for line in content.split("\n"):
    if line:
        if line.startswith("---"):
            lastLineWasPrefix = True

            strippedLine = line.lstrip("---")

            if strippedLine.startswith("@param"):
                params = strippedLine.removeprefix(
                    "@param ",
                ).split(" ")

                functionMeta["params"].append({"name": params[0], "type": params[1]})
            elif strippedLine.startswith("@return"):
                functionMeta["return"].append(strippedLine.removeprefix("@return "))
            elif strippedLine.startswith("@field") or strippedLine.startswith("@class"):
                pass
            else:
                functionMeta["description"].append(line.removeprefix("---"))
        else:
            if lastLineWasPrefix:
                lastLineWasPrefix = False
                if line.startswith("function "):
                    functionName = line.removeprefix("function ").split("(")[0]

                    functions[functionName] = functionMeta

                    functionMeta = {"description": [], "params": [], "return": []}

functions = dict(sorted(functions.items()))

for functionName, functionMeta in functions.items():
    markdownFile.write("### " + functionName.split(":")[1] + "\n")

    paramsList = []

    for parami, param in enumerate(functionMeta["params"]):
        paramsList.append(f"{param["name"]}: {param["type"]}")

    if not functionMeta["return"]:
        functionMeta["return"].append("nil")

    markdownFile.write(
        f"""```lua
    (method) {functionName}({", ".join(paramsList)})
    -> {", ".join(functionMeta["return"])}
    ```\n"""
    )

    # markdownFile.write("## " + line.lstrip("function ") + "\n")

    markdownFile.write("\n".join(functionMeta["description"]) + "\n")

    # markdownFile.write("\n\n")

    # for param in functionMeta["params"]:
    #     print(f"param {param["name"]}: {param["type"]}")

    # for ret in functionMeta["return"]:
    #     print(f"returns a {ret}.")
