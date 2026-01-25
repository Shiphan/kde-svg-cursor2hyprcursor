#!/usr/bin/env nu

use std/assert

def main [
	source: path,
	--working: path = "./working",
	--target: path = "./target",
	--cursors-directory: string = "hyprcursors",
	--resize-algorithm: string = "bilinear",
] {
	convert-index-theme $source $working $cursors_directory
	convert-cursors $source $working $cursors_directory $resize_algorithm

	mkdir $target
	hyprcursor-util --create $working --output $target

	null
}

def convert-index-theme [source: path, working: path, cursors_dir: string] {
	mkdir $working
	let index_theme = open $"($source)/index.theme" --raw
		| from ini
		| get "Icon Theme"

	{
		cursors_directory: $cursors_dir,
		name: $index_theme.Name?,
		description: $index_theme.Comment?,
		version: null,
		author: null,
	}
		| compact
		| { General: $in }
		| save $"($working)/manifest.toml"
}

def convert-cursors [source: path, working: path, cursors_dir: string, resize_algorithm: string] {
	mkdir $"($working)/($cursors_dir)"
	let alias = ls --short-names --long $"($source)/cursors_scalable"
		| where type == symlink
		| select name target
		| reduce --fold {} {|it, acc|
			$acc | upsert $it.target { $in | default [] | append $it.name }
		}
	ls --short-names $"($source)/cursors_scalable"
		| where type == dir
		| get name
		| each {|name|
			mkdir $"($working)/($cursors_dir)/($name)"
			convert-metadata $source $name ($alias | get --optional $name | default []) $resize_algorithm
				| compact --empty
				| { General: $in }
				| save $"($working)/($cursors_dir)/($name)/meta.toml"
			ls --full-paths $"($source)/cursors_scalable/($name)"
				| where name ends-with ".svg"
				| get name
				| each { cp $in $"($working)/($cursors_dir)/($name)/" }
		}
}

def convert-metadata [source: path, dir_name: string, alias: list<string>, resize_algorithm: string] {
	let metadata = open $"($source)/cursors_scalable/($dir_name)/metadata.json"
		| into float nominal_size hotspot_x hotspot_y
	let svg = $metadata
		| get filename
		| reduce --fold {} {|it, acc|
			let svg = open $"($source)/cursors_scalable/($dir_name)/($it)" --raw | from xml
			$acc | upsert $it $svg
		}

	let define_override = $alias | str join ";"
	if ($metadata | length) > 1 {
		convert-animated ($metadata | into float delay) $svg $define_override $resize_algorithm
	} else {
		convert-static ($metadata | get 0) $svg $define_override $resize_algorithm
	}
}

def convert-static [
	metadata: record<filename: string, nominal_size: float, hotspot_x: float, hotspot_y: float>,
	svg: record,
	define_override: string,
	resize_algorithm: string,
] {
	let svg_size = $svg | get $metadata.filename | get-svg-size
	{
		resize_algorithm: $resize_algorithm,
		hotspot_x: ($metadata.hotspot_x / $metadata.nominal_size),
		hotspot_y: ($metadata.hotspot_y / $metadata.nominal_size),
		nominal_size: ($metadata.nominal_size / $svg_size),
		define_override: $define_override,
		define_size: $"0,($metadata.filename)",
	}
}

def convert-animated [
	metadata: list<record<filename: string, nominal_size: float, hotspot_x: float, hotspot_y: float, delay: float>>,
	svg: record,
	define_override: string,
	resize_algorithm: string,
] {
	let first_frame = $metadata | get 0
	let svg_size = $svg | get $first_frame.filename | get-svg-size
	let nominal_size = $first_frame.nominal_size / $svg_size
	let frames = $metadata
		| each {|frame|
			(assert equal [$frame.hotspot_x, $frame.hotspot_y] [$first_frame.hotspot_x, $first_frame.hotspot_y]
				"Hyprcursor only support one hotspot even for animated cursor")
			let svg_size = $svg | get $frame.filename | get-svg-size
			(assert equal ($frame.nominal_size / $svg_size) $nominal_size
				"Hyprcursor only support one nominal size even for animated cursor")

			$"0,($frame.filename),($frame.delay)"
		}
	{
		resize_algorithm: $resize_algorithm,
		hotspot_x: ($first_frame.hotspot_x / $first_frame.nominal_size),
		hotspot_y: ($first_frame.hotspot_y / $first_frame.nominal_size),
		nominal_size: $nominal_size,
		define_override: $define_override,
		define_size: ($frames | str join ";"),
	}
}

def get-svg-size []: any -> float {
	let width = $in.attributes.width | into float
	let height = $in.attributes.height | into float
	assert equal $width $height "Hyprcursor only support cursor with aspect ratio of 1:1"
	$width
}
