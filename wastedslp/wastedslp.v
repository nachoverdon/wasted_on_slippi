module wastedslp

import encoding.binary { big_endian_u32 }
import os { File }
import time { Duration }

const (
	slp_ext = "slp"
	hours_in_day = 24
	days_in_week = 7
	weeks_in_month = 4
	months_in_year = 12
	raw_data_offset = 11
	last_frame_offset = 70
	extra_frames = 120
)

struct Wasted {
	pub:
		directory string
		games u32
		duration Duration
		hours f64
		days f64
		weeks f64
		months f64
		years f64
}

// 🍺🥴
// Get the information about wasted time on Slippi
pub fn get_wasted(directory string) ?Wasted {
	// Check if exists and is a directory
	if !os.exists(directory) || !os.is_dir(directory) {
		return error("Invalid directory")
	}

	// Get all .slp files in directory AND subdirectories
	slp_files := os.walk_ext(directory, slp_ext)

	if slp_files.len == 0 {
		return error("No .slp files found")
	}

	// Calculate total duration of the replays
	duration := get_replays_duration(slp_files)
	hours := duration.hours()
	days := hours / hours_in_day
	weeks := days / days_in_week
	months := weeks / weeks_in_month
	years := months / months_in_year

	return Wasted {
		directory: directory
		games: u32(slp_files.len)
		duration: duration
		hours: hours
		days: days
		weeks: weeks
		months: months
		years: years
	}
}

// Get the total duration of the replays
pub fn get_replays_duration(slp_files []string) Duration {
	mut total_frames := u32(0)

	for file_name in slp_files {
		mut file := os.open(file_name) or { continue }
		defer { file.close() }

		frames := read_frames_from_slp_file(file)

		total_frames += frames
	}

	return Duration(total_frames * time.second)
}

// Read 4 bytes from the given file at the given position as a big endian u32
fn get_u32_at(file File, pos u64) u32 {
	return big_endian_u32(file.read_bytes_at(4, pos))
}

// Reads the property "lastFrame" from the metadata of the given .slp file
pub fn read_frames_from_slp_file(file File) u32 {
	// 11 is the offset until the length of the raw data
	// 70 = Offset until start of lastFrame
	mut raw_length := get_u32_at(file, raw_data_offset) + last_frame_offset

	// + 2 extra seconds (120 frames) because ready? go!
	return get_u32_at(file, raw_length) + extra_frames
}
