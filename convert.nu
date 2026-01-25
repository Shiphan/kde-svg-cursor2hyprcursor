#!/usr/bin/env nu

def main [source: path, --working: path = "./working", --target: path = "./target", --cursors-directory: string = "hyprcursors"] {
	convert-index-theme $source $working $cursors_directory
	convert-cursors $source $working $cursors_directory

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

def convert-cursors [source: path, working: path, cursors_dir: string] {
	mkdir $"($working)/($cursors_dir)"
	let alias = ls --short-names --long $"($source)/cursors_scalable"
		| where type == symlink
		| select name target
		| reduce {|it, acc|
			$acc | upsert $it.target { $in | default [] | append $it.name }
		}
	ls --short-names $"($source)/cursors_scalable"
		| where type == dir
		| get name
		| each {|name|
			mkdir $"($working)/($cursors_dir)/($name)"
			convert-metadata $source $name ($alias | get --optional $name | default [])
				| { General: $in }
				| save $"($working)/($cursors_dir)/($name)/meta.toml"
			ls --full-paths $"($source)/cursors_scalable/($name)"
				| where name ends-with ".svg"
				| get name
				| each { cp $in $"($working)/($cursors_dir)/($name)/" }
		}
}

def convert-metadata [source: path, dir_name: string, alias: list<string>] {
	let metadata = open $"($source)/cursors_scalable/($dir_name)/metadata.json"
		| into float nominal_size hotspot_x hotspot_y

	let define_override = $alias | str join ";"
	if ($metadata | length) > 1 {
		convert-animated ($metadata | into float delay) $define_override
	} else {
		convert-static ($metadata | get 0) $define_override
	}
}

def convert-static [metadata: record<filename: string, nominal_size: float, hotspot_x: float, hotspot_y: float>, define_override: string] {
	{
		resize_algorithm: "bilinear",
		hotspot_x: ($metadata.hotspot_x / $metadata.nominal_size),
		hotspot_y: ($metadata.hotspot_y / $metadata.nominal_size),
		nominal_size: 1.0,
		define_override: $define_override,
		define_size: $"($metadata.nominal_size),($metadata.filename)",
	}
}

def convert-animated [metadata: list<record<filename: string, nominal_size: float, hotspot_x: float, hotspot_y: float, delay: float>>, define_override: string] {
	let first_frame = $metadata | get 0
	let frames = $metadata
		| each { $"($in.nominal_size),($in.filename),($in.delay)" }
	{
		resize_algorithm: "bilinear",
		hotspot_x: ($first_frame.hotspot_x / $first_frame.nominal_size),
		hotspot_y: ($first_frame.hotspot_y / $first_frame.nominal_size),
		nominal_size: 1.0,
		define_override: $define_override,
		define_size: ($frames | str join ";"),
	}
}
