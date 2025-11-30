import clipboard
import math { round_sig }
import os
import gui
import nachoverdon.wastedslp { get_wasted }

const hours_in_day = 24
const days_in_week = 7
const weeks_in_month = 4
const months_in_year = 12
const cwd = '.'
const empty = ''
const days = 'days'
const weeks = 'weeks'
const months = 'months'
const years = 'years'
const title = 'Wasted on Slippi'
const calculating = 'Calculating...'
const copy_clipboard = 'Copy to clipboard'
const reload = '⟲'
const based_on = 'Based on the replays found in:'

struct App {
	directory string
pub mut:
	text string
}

fn main() {
	// Check argv for folder path
	directory := os.abs_path(if os.args.len < 2 { cwd } else { os.args[1] })

	mut app := &App{
		text:      calculating
		directory: &directory
	}

	println(calculating)

	// Don't show window if called with '--no-ui'
	show_ui := !os.args.any(it == '--no-ui')

	if show_ui {
		start_ui(app)
	} else {
		get_text(mut &app)
		setup_copy(app)
	}
}

fn get_text(mut app &App) {
	get_wasted_text(mut app) or {
		eprintln('Error: ${err}')
		exit(0)
	}
	app.text = '${based_on}\n${app.directory}\n\n${app.text}'
}

fn setup_copy(app App) {
	// Copy to clipboard if called with '--copy'
	copy := os.args.any(it == '--copy')

	if copy {
		copy_to_clipboard(app.text)
	}
}

fn get_wasted_text(mut app &App) ! {
	wasted := get_wasted(app.directory) or { return err }

	wasted_text := 'You have played ${wasted.games} games and wasted ${round_sig(wasted.hours,
		2)} hours on Slippi'
	equivalent := fn (a f64, b f64, time_num f64, time_string string) string {
		return if a >= b {
			'\nor the equivalent to ${round_sig(time_num, 2)} ${time_string}...'
		} else {
			empty
		}
	}
	wasted_days := equivalent(wasted.hours, hours_in_day, wasted.days, days)
	wasted_weeks := equivalent(wasted.days, days_in_week, wasted.weeks, weeks)
	wasted_months := equivalent(wasted.weeks, weeks_in_month, wasted.months, months)
	wasted_years := equivalent(wasted.months, months_in_year, wasted.years, years)
	whole_text := wasted_text + wasted_days + wasted_weeks + wasted_months + wasted_years

	app.text = whole_text
}

fn on_init(mut w gui.Window) {
	mut app := w.state[App]()

	w.update_view(main_view)
	get_text(mut &app)
	w.resize_to_content()
	setup_copy(app)
}

fn start_ui(app &App) {
	mut window := gui.window(
		state:   app
		width:   540
		height:  200
		title:   title
		on_init: on_init
	)

	window.run()
}

fn main_view(window &gui.Window) gui.View {
	app := window.state[App]()

	mut label := gui.text(
		text: app.text
		mode: .multiline
	)

	mut copy_button := gui.button(
		content:  [gui.text(text: copy_clipboard)]
		on_click: fn [app] (_ &gui.Layout, mut e gui.Event, mut w gui.Window) {
			copy_to_clipboard(app.text)
		}
	)

	mut reload_button := gui.button(
		content:  [gui.text(text: reload)]
		on_click: fn (_ &gui.Layout, mut e gui.Event, mut w gui.Window) {
			mut app := w.state[App]()

			app.text = calculating
			get_text(mut &app)
			w.resize_to_content()
		}
	)

	return gui.column(
		padding: gui.padding(10, 10, 10, 10)
		content: [
			label,
			gui.row(
				content: [
					copy_button,
					reload_button,
				]
			),
		]
	)
}

fn copy_to_clipboard(text string) {
	mut clip := clipboard.new()

	clip.copy(text)
}
