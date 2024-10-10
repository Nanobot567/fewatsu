default: build run

[private]
incrementBuildNumber:
  #! /bin/python3
  from sys import argv

  f = open("src/pdxinfo","r")
  content = f.read()
  f.close()

  splitnl = content.split("\n")
  sc = splitnl[5].split("=")
  buildnum = sc[1]

  splitnl[5] = f"buildNumber={str(int(buildnum)+1)}"

  f = open("src/pdxinfo","w")

  for i in splitnl:
      if splitnl[len(splitnl)-1] == i:
          f.write(f"{i}")
      else:
          f.write(f"{i}\n")

  print(splitnl)


build:
  @just incrementBuildNumber

  pdc -q -sdkpath ~/Documents/PlaydateSDK/ src fewatsu-demo

run:
  PlaydateSimulator fewatsu-demo.pdx

release:
  just build
  -rm fewatsu-demo.pdx.zip
  zip -rq fewatsu-demo.pdx.zip fewatsu-demo.pdx

  -rm -rf fewatsu.zip
  mkdir -p fewatsu-lib
  cp src/lib/* fewatsu-lib/ -r
  cd fewatsu-lib && zip -rq ../fewatsu-lib.zip *
  -rm -rf fewatsu-lib/
