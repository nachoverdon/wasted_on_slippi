# Wasted on Slippi

A little tool that calculates how much time you have spent playing
Super Smash Bros. Melee based on the replays of a given directory and
subdirectories.

## Usage

### As an executable

Either run `wasted_on_slippi` from the target directory or pass the directory as
an argument:
```
wasted_on_slippi "C:/Users/bazoo/Documents/Slippi" [options]
```

There are 2 options:
*   `--no-ui`: This will not create a window and will just print the result.
*   `--copy`: This will automatically copy the result to the clipboard.

### As a module

Install the module

```
v install wastedslp
```

Import it and use it
```v
import wastedslp

fn main() {
    directory := "C:/user/replays"
    wasted := wastedslp.get_wasted(directory)  or { panic(err )}

    slp_files := os.walk_ext(directory, slp_ext)
    wastedslp.get_replays_duration(slp_files)

    slp_file := os.open("C:/user/replays/jv5.slp") or { panic(err) }
    wastedslp.read_frames_from_slp_file(slp_file)
}
```


## Build

It uses `ui` module, which requires a few dependencies on Linux.
Check [this link](https://github.com/vlang/ui#dependencies) for more info

```
git clone https://github.com/nachoverdon/wasted_on_slippi
cd wasted_on_slippi
v install
v -prod .
```
