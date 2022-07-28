module main

import clipboard
import math { round_sig }
import os
import ui
import wastedslp { get_wasted, get_replays_duration, read_frames_from_slp_file }

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
	whole_text := wasted_text + wasted_days + wasted_weeks + wasted_months + wasted_years

	// Don't show window if called with '--no-ui'
	show_ui := !os.args.any(it == "--no-ui")

	if show_ui {
		show_window(whole_text)
	} else {
		println(whole_text)
	}

	// Copy to clipboard if called with '--copy'
	copy := os.args.any(it == "--copy")

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