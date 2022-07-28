module wastedslp

import encoding.binary { big_endian_u32 }
import os { File }
import time { Duration }
import math { round_sig }
import ui
import clipboard

const (
	slp_ext = "slp"
	cwd	 = "."
	hours_in_day = 24
	days_in_week = 7
	weeks_in_month = 4
	months_in_year = 12
	raw_data_offset = 11
	last_frame_offset = 70
	extra_frames = 120
	empty = ""
)

struct Wasted {
	directory string
	games u32
	duration Duration
	hours f64
	days f64
	weeks f64
	months f64
	years f64
}

fn main() {
	// Check argv for folder path
	directory := if os.args.len < 2 { cwd } else { os.args[1] }

	wasted := get_wasted(directory) or {
		eprintln("Error: $err")
		exit(0)
	}

	wasted_text := "You have played ${wasted.games} games and wasted ${round_sig(wasted.hours, 2)} hours on Slippi"
	equivalent := fn (a f64, b f64, time f64, time_string string) string {
		return if a >= b {
			"\nor the equivalent of ${round_sig(time, 2)} ${time_string}..."
		} else { empty }
	}
	wasted_days := equivalent(wasted.hours, hours_in_day, wasted.days, "days")
	wasted_weeks := equivalent(wasted.days, days_in_week, wasted.weeks, "weeks")
	wasted_months := equivalent(wasted.weeks, weeks_in_month, wasted.months, "months")
	wasted_years := equivalent(wasted.months, months_in_year, wasted.years, "years")

	whole_text := "$wasted_text$wasted_days$wasted_weeks$wasted_months$wasted_years"

	// Don't show window if called with '--no-ui'
	show_ui := !os.args.any(it == "--no-ui")
	copy := os.args.any(it == "--copy")

	if show_ui {
		show_window(whole_text)
	} else {
		println(whole_text)
	}

	if copy {
		copy_to_clipboard(whole_text)
	}
}

fn show_window(whole_text string) {
	mut window := ui.window(
		width: 460,
		height: 135,
		title: "Wasted on Slippi"
		children: [
			ui.column(
				spacing: 5
				height: 20
				margin_: 15
				children: [
					ui.label(
						text: &whole_text
						justify: ui.center_left
					),
					ui.button(
						text: "Copy to clipboard"
						on_click: fn [whole_text] (btn &ui.Button) {
							copy_to_clipboard(whole_text)
						}
					)
				]
			)
		]
	)

	ui.run(window)
}

fn copy_to_clipboard(text string) {
	mut clip := clipboard.new()

	clip.copy(text)
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
