module main

import encoding.binary { big_endian_u32 }
import os { File }
import time { Duration }

const (
	slp_ext = "slp"
)

fn main() {
	// Check argv for folder path
	root_directory := if os.args.len < 2 { "." } else { os.args[1] }
	// Check folder for .slp and subfolders
	slp_files := os.walk_ext(root_directory, slp_ext)

	mut total_frames := u32(0)

	// For each .slp
	for file_name in slp_files {
		mut file := os.open(file_name) or { continue }
		defer { file.close() }

		// Read amount of frames
		frames := read_frames_from_slp_file(file_name, file)

		total_frames += frames
	}

	duration := Duration(total_frames * time.second)
	hours := duration.hours()

	println("Played ${slp_files.len} games and wasted ${hours} hours on Slippi")

	if hours >= 24 {
		days := hours / 24

		println("... or ${days} days...")

		if days >= 7 {
			weeks := days / 7

			println("... or ${weeks} weeks...")

			if weeks >= 4 {
				months := weeks / 4

				println("... or ${months} months...")

				if months >= 12 {
					years := months / 12

					println("... or ${years} years...")
					// Here lies the pharaoh
				}
			}
		}
	}
}

fn get_length_of_raw(file File) u32 {
	// 11 is the offset until the length of the raw data
	return big_endian_u32(file.read_bytes_at(4, 11))
}

fn read_frames_from_slp_file(file_name string, file File) u32 {
	mut length := get_length_of_raw(file)

	// 70 = Offset until start of lastFrame
	offset := u32(70)
	// + 2 extra seconds because ready? go!
	last_frame := big_endian_u32(file.read_bytes_at(4, length + offset)) + 120

	return last_frame
}
