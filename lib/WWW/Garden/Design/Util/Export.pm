package WWW::Garden::Design::Util::Export;

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Encode 'encode';

use Imager;
use Imager::Fill;

use WWW::Garden::Design::Database;

use Mojo::Log;

use Moo;

use Sort::Naturally;

use SVG::Grid;

use Text::CSV;
use Text::Xslate 'mark_raw';

use Types::Standard qw/Any Int HashRef Str/;

extends qw/WWW::Garden::Design::Database::Base/;

has export_type =>
(
	default		=> sub{return 0},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has output_file =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 1,
);

has standalone_page =>
(
	default		=> sub{return 0},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has title_font =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

our $VERSION = '0.95';

# -----------------------------------------------

sub BUILD
{
	my($self)            = @_;
	my($export_type)     = $self -> export_type;
	my($standalone_page) = $self -> standalone_page;

	$self -> title_font
	(
		Imager::Font -> new
		(
			color	=> Imager::Color -> new(0, 0, 0), # Black.
			file	=> '/usr/share/fonts/truetype/freefont/FreeMono.ttf',
			size	=> 16,
		) || die "Error. Can't define title font: " . Imager -> errstr
	);

	if ($export_type < 0)
	{
		$self -> export_type(0);
	}
	elsif ($export_type > 1)
	{
		$self -> export_type(1);
	}

	if ($standalone_page < 0)
	{
		$self -> standalone_page(0);
	}
	elsif ($standalone_page > 1)
	{
		$self -> standalone_page(1);
	}

	my($log_path) = "$ENV{HOME}/perl.modules/WWW-Garden-Design/log/development.log";

	$self -> db
	(
		WWW::Garden::Design::Database -> new
		(
			logger => Mojo::Log -> new(path => $log_path)
		)
	);

}	# End of BUILD.

# -----------------------------------------------

sub attribute_types2csv
{
	my($self, $csv)				= @_;
	my($attribute_types_table)	= $self -> db -> read_table('attribute_types');
	my($file_name)				= $self -> output_file =~ s/flowers.csv/attribute_types.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/name sequence range/);

	print $fh $csv -> string, "\n";

	for my $attribute_type (@$attribute_types_table)
	{
		$csv -> combine
		(
			$$attribute_type{name},
			$$attribute_type{sequence},
			$$attribute_type{range},
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of attribute_types2csv.

# -----------------------------------------------

sub attributes2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/attributes.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/common_name attribute_name range/);

	print $fh $csv -> string, "\n";

	my($common_name);

	for my $flower (@$flowers)
	{
		$common_name = $$flower{common_name};

		for my $attribute (@{$$flower{attributes} })
		{
			$csv -> combine
			(
				$common_name,
				$$attribute{name},
				$$attribute{range},
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of attributes2csv.

# -----------------------------------------------

sub as_csv
{
	my($self) = @_;

	die "No output file specified\n" if (! $self -> output_file);

	my($csv)		= Text::CSV -> new({always_quote => 1, binary => 1});
	my($flowers)	= $self -> flowers2csv($csv);

	$self -> attributes2csv($csv, $flowers);
	$self -> flower_locations2csv($csv, $flowers);
	$self -> notes2csv($csv, $flowers);
	$self -> images2csv($csv, $flowers);
	$self -> urls2csv($csv, $flowers);
	$self -> attribute_types2csv($csv);

	my($color_id2hex)	= $self -> colors2csv($csv);
	my($garden_id2name)	= $self -> gardens2csv($csv);
	my($objects)		= $self -> objects2csv($csv, $color_id2hex);

	$self -> constants2csv($csv);
	$self -> object_locations2csv($csv, $objects, $garden_id2name);
	$self -> db -> logger -> info('Finished exporting all CSV files');

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of as_csv.

# -----------------------------------------------

sub as_html
{
	my($self)        = @_;
	my($export_type) = $self -> export_type;

	my(%column);

	# Warning: The line in web.site.xml which runs this script must not use command line options.
	# That means, that whatever options that code needs must be the defaults.
	# Warning: These options are documented in scripts/export.as.html.pl Be consistent!

	if ($export_type == 0)
	{
		%column =
		(
			'#' =>
			{
				column_name	=> 'count', # I.e. database column name.
				order		=> 1,
			},
			'Native' =>
			{
				column_name	=> 'native',
				order		=> 2,
			},
			'Scientific name' =>
			{
				column_name	=> 'scientific_name',
				order		=> 3,
			},
			'Common name' =>
			{
				column_name	=> 'common_name',
				order		=> 4,
			},
			'Aliases' =>
			{
				column_name	=> 'aliases',
				order		=> 5,
			},
			'Thumbnail <span class = "index">(clickable)</span>' =>
			{
				column_name	=> 'thumbnail_file_name',
				order		=> 6,
			},
		);
	}
	else
	{
		%column =
		(
			'#' =>
			{
				column_name	=> 'count',
				order		=> 1,
			},
			'Native' =>
			{
				column_name	=> 'native',
				order		=> 2,
			},
			'Scientific name' =>
			{
				column_name	=> 'scientific_name',
				order		=> 3,
			},
			'Common name' =>
			{
				column_name	=> 'common_name',
				order		=> 4,
			},
			'Aliases' =>
			{
				column_name	=> 'aliases',
				order		=> 5,
			},
			'Thumbnail' =>
			{
				column_name	=> 'thumbnail_file_name',
				order		=> 6,
			},
 		);
	}

	my($count)		= 0;
	my($flowers)	= $self -> db -> read_flowers_table;
	my(@heading)	= map{ {td => mark_raw($_)} } sort{$column{$a}{order} <=> $column{$b}{order} } keys %column;
	my(@row)		= [@heading];
	my($width)		= 40;

	my(@aliases);
	my($column_name);
	my(@fields);
	my(@line);
	my($native, $name);
	my($offset);
	my($thumbnail);
	my($text);

	for my $flower (@$flowers)
	{
		$$flower{'count'}	= ++$count;
		@aliases			= ();
		@line				= ();

		for (@{$$flower{attributes} })
		{
			$native = $$_{range} if ($$_{name} eq 'native');
		}

		for my $key (sort{$column{$a}{order} <=> $column{$b}{order} } keys %column)
		{
			$column_name	= $column{$key}{column_name};
			$name			= ($column_name eq 'native') ? $native : $$flower{$column_name};

			if ($key eq 'Aliases')
			{
				@fields	= split(/\s*,\s*/, $name);
				$text	= '';

				while (my $field = shift @fields)
				{
					if (length($text . $field) > $width)
					{
						push @aliases, $text;

						$text = $field;
					}
					else
					{
						$text .= $text ? ", $field" : $field;
					}
				}

				$text = join(',<br>', @aliases, $text);
			}
			else
			{
				$text = $name;
			}

			push @line, {td => mark_raw($text)};
		}

		$offset			= $#line;
		$line[$offset]	=
			{
				td => mark_raw
				(
					"<a href='$$flower{web_page_url}'><img src='$$flower{thumbnail_url}'></img></a>"
				)
			};

		push @row, [@line];
	}

	push @row, [@heading];

	my($constants)	= $self -> db -> read_constants_table;
	my($tx)			= Text::Xslate -> new
	(
		input_layer => '',
		path        => $$constants{template_path},
	);

	return encode('utf-8', $tx -> render
	(
		$self -> standalone_page ? 'standalone.page.tx' : 'basic.table.tx',
		{
			row => \@row,
		}
	) );

} # End of as_html.

# -----------------------------------------------

sub colors2csv
{
	my($self, $csv)		= @_;
	my($color_table)	= $self -> db -> read_table('colors');
	my($file_name)		= $self -> output_file =~ s/flowers.csv/colors.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/color hex name rgb/);

	print $fh $csv -> string, "\n";

	my(%color_id2hex);

	for my $row (sort{uc($$a{color}) cmp uc($$b{color}) || $$a{hex} cmp $$b{hex} } @$color_table)
	{
		$color_id2hex{$$row{id} } = $$row{hex};

		$csv -> combine
		(
			$$row{color},
			$$row{hex},
			$$row{name},
			$$row{rgb},
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

	return \%color_id2hex;

} # End of colors2csv.

# -----------------------------------------------

sub constants2csv
{
	my($self, $csv)	= @_;
	my($constants)	= $self -> db -> constants;
	my($file_name)	= $self -> output_file =~ s/flowers.csv/constants.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/name value/);

	print $fh $csv -> string, "\n";

	for my $name (sort keys %$constants)
	{
		$csv -> combine
		(
			$name,
			$$constants{$name},
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of constants2csv.

# -----------------------------------------------

sub export_all_pages
{
	my($self)					= @_;
	my($attribute_types_table)	= $self -> db -> read_table('attribute_types');
	my($constants)				= $self -> db -> constants;
	my($flowers)				= $self -> db -> read_flowers_table;

	$self -> db -> logger -> info("flower_dir: $$constants{flower_dir}");

	my(%attribute_sequence);

	for (values @$attribute_types_table)
	{
		$attribute_sequence{$$_{name} } = $$_{sequence};
	}

	my($tx) = Text::Xslate -> new
	(
		input_layer => '',
		path        => $$constants{template_path},
	);

	my(@attributes, $aliases);
	my(@images);
	my(@notes);
	my($pig_latin);
	my($scientific_name);
	my($text);
	my($url, @urls);
	my($web_page_name);

	for my $flower (@$flowers)
	{
		$aliases			= $$flower{aliases};
		@attributes			= ();
		@images				= ();
		@notes				= ();
		$scientific_name	= $$flower{scientific_name};
		$pig_latin			= $$flower{pig_latin};
		@urls				= ();

		push @attributes,
		[
			{td => 'Attribute'},
			{td => 'Range'},
		];

		for my $attribute (sort{$$a{sequence} <=> $$b{sequence} } @{$$flower{attributes} })
		{
			push @attributes,
			[
				{td => $$attribute{name} },
				{td => $$attribute{range} },
			];
		}

		push @images,
		[
			{td => 'Descriptions'},
			{td => 'Images'},
		];

		for my $image (@{$$flower{images} })
		{
			push @images,
			[
				{td => mark_raw($$image{description})},
				{td => mark_raw("<img src = '$$image{file_name}'>")},
			];
		}

		push @notes,
		[
			{td => 'Notes'},
		];

		for my $note (@{$$flower{notes} })
		{
			$text = $$note{note};

			if ($text =~ /^http/)
			{
				$text = "» <a href = '$text'>$$note{note}</a>";
			}
			else
			{
				$text = "» $text";
			}

			push @notes,
			[
				{td => mark_raw($text)},
			];
		}

		push @urls,
		[
			{td => '#'},
			{td => 'URLs'},
		];

		for my $url (@{$$flower{urls} })
		{
			push @urls,
			[
				{td => $$url{sequence}},
				{td => mark_raw("<a href = '$$url{url}'>$$url{url}</a>")},
			];
		}

		$web_page_name = "$$constants{homepage_dir}$$constants{flower_dir}/$pig_latin.html";

		$self -> db -> logger -> info("Writing $web_page_name");

		open(my $fh, '>:encoding(utf-8)', $web_page_name);
		print $fh $tx -> render
					(
						'individual.page.tx',
						{
							aliases			=> $aliases eq '-' ? '' : "Common name(s): $aliases",
							attributes		=> \@attributes,
							notes			=> \@notes,
							images			=> \@images,
							scientific_name	=> $scientific_name,
							title			=> $scientific_name,
							urls			=> \@urls,
						}
					);
		close $fh;
	}

	$self -> db -> logger -> info('Finished exporting all HTML files');

} # End of export_all_pages.

# -----------------------------------------------

sub export_garden_layout
{
	my($self, $garden_name)	= @_;
	my($constants)			= $self -> db -> constants;
	my($flowers)			= $self -> db -> read_flowers_table;
	my($Garden)				= ucfirst($garden_name);
	my($garden_table)		= $self -> db -> read_table('gardens');
	my($objects)			= $self -> db -> read_objects_table;
	my($max_x)				= 0;
	my($max_y)				= 0;
	my($x_offset)			= $$constants{x_offset};
	my($y_offset)			= $$constants{y_offset};

	my(%garden_name);

	for my $garden (@$garden_table)
	{
		$garden_name{$$garden{id} } = $$garden{name};
	}

	my(%object_name);

	for my $object (@$objects)
	{
		$object_name{$$object{id} } = $$object{name};
	}

	# 1: Set the parameters.

	my($id);
	my(%location_xy);
	my($x);
	my($y);

	for my $flower (@$flowers)
	{
		for my $location (@{$$flower{flower_locations} })
		{
			next if ($garden_name{$$location{garden_id} } ne $garden_name);

			$id					= $$location{id};
			$x					= $$location{x};
			$y					= $$location{y};
			$max_x				= $x	if ($x > $max_x);
			$max_y				= $y	if ($y > $max_y);
			$location_xy{$id}	= []	if (! $location_xy{$id});

			push @{$location_xy{$id} }, [$x, $y];
		}
	}

	$self -> db -> logger -> info("Max (x, y) after processing 'flower_locations': ($max_x, $max_y)");

	for my $object (@$objects)
	{
		for my $feature (@{$$object{object_locations} })
		{
			next if ($garden_name{$$feature{garden_id} } ne $garden_name);

			$x		= $$feature{x};
			$y		= $$feature{y};
			$max_x	= $x	if ($x > $max_x);
			$max_y	= $y	if ($y > $max_y);
		}
	}

	$self -> db -> logger -> info("Max (x, y) after processing 'object_locations': ($max_x, $max_y)");

	my($x_cell_count)	= $max_x;
	my($y_cell_count)	= $max_y;
	my($image)			= SVG::Grid -> new
	(
		cell_width		=> $$constants{cell_width},
		cell_height		=> $$constants{cell_height},
		x_cell_count	=> $x_cell_count,
		y_cell_count	=> $y_cell_count,
		x_offset		=> $$constants{x_offset},
		y_offset		=> $$constants{y_offset},
	);

	$image -> grid(stroke => 'blue');

	# 2: Add the object locations to the grid.

	my($file_name);
	my($image_id);

	for my $object (@$objects)
	{
		for my $feature (@{$$object{object_locations} })
		{
			next if ($garden_name{$$feature{garden_id} } ne $garden_name);

			$file_name	= $self -> db -> clean_up_icon_name($$object{name});

			$image_id = $image -> svg -> image
			(
				height	=> $$constants{cell_height},
				href	=> "$$object{icon_url}/$file_name.png",
				width	=> $$constants{cell_width},
				x		=> $x_offset + $$constants{cell_width} * $$feature{x}, # Cell co-ord.
				y		=> $y_offset + $$constants{cell_height} * $$feature{y}, # Cell co-ord.
			);
		}
	}

	# 3: Add the flowers to the grid.

	my($pig_latin);

	for my $flower (@$flowers)
	{
		$pig_latin = $$flower{pig_latin};

		for my $location (@{$$flower{flower_locations} })
		{
			next if ($garden_name{$$location{garden_id} } ne $garden_name);

			$image_id = $image -> image_link
			(
				href	=> $$flower{web_page_url},
				image	=> $$flower{thumbnail_url},
				target	=> 'new_window',
				x		=> $$location{x}, # Cell co-ord.
				y		=> $$location{y}, # Cell co-ord.
			);
		}
	}

	# 4: Add some annotations and write the layout SVG.

	$image -> text
	(
		'font-size'		=> 32,
		'font-weight'	=> '400',
		text			=> "$Garden Garden",
		x				=> $image -> x_offset + 8,		# Pixel co-ord.
		y				=> $image -> y_offset / 2 + 8,	# Pixel co-ord.
	);
	$image -> text
	(
		'font-size'		=> 32,
		'font-weight'	=> '400',
		text			=> '--> N',
		x				=> $image -> width - 2 * $image -> cell_width,	# Pixel co-ord.
		y				=> $image -> y_offset / 2,						# Pixel co-ord.
	);
	$image -> text
	(
		'font-size'		=> 32,
		'font-weight'	=> '400',
		text			=> 'Block is 11.7m wide',
		x				=> $image -> width - 6 * $image -> cell_width,	# Pixel co-ord.
		y				=> $image -> height,							# Pixel co-ord.
	);

	$file_name = "$$constants{homepage_dir}$$constants{flower_url}/$garden_name.garden.layout.svg";

	$self -> db -> logger -> info("Writing to $file_name");

	$image -> write(output_file_name => $file_name);

	# 4: Output some HTML.

	my($other_garden)	= ($garden_name eq 'front') ? 'back' : 'front';
	my($Other_garden)	= ucfirst $other_garden;

	my(@garden_index);

	push @garden_index, <<EOS;
<html>
	<head>
		<title>$Garden Garden Layout</title>
		<meta http-equiv = "Content-Type" content = "text/html; charset=utf-8" />
		<link rel = 'stylesheet' type = 'text/css' href = '/assets/css/www/garden/design/homepage.css'>
	</head>
	<body>
		<br />
		<div class = 'centered'><span class = 'purple_on_red_title' id = 'top'>The $Garden Garden Layout</span></div>
		<br />
		<table align = 'center'>
			<tr><td>Part 1: The $Garden Garden Layout (SVG image), with clickable flower thumbnails in situ</td></tr>
			<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/$other_garden.garden.layout.html'>Part 2: The $Other_garden Garden Layout (separate page)</a></td></tr>
			<tr><td><a href = '#part_4'>Part 3: The Database Schema</a></td></tr>
			<tr><td><a href = '$$constants{homepage_url}/Flowers.html'>Part 4 : The Flower Catalog</a></td></tr>
		</table>

		<br />

		<h2 align = 'center' id = 'part_1'>Part 1: The $Garden Garden Layout (SVG image), with clickable flower thumbnails in situ</h2>

		<table align = 'center'>
			<tr><td align = 'center'>
				<object data = '$$constants{homepage_url}$$constants{flower_url}/$garden_name.garden.layout.svg'></object>
			</td></tr>
		</table>

		<br />

		<table align = 'center'><tr><td align = 'center'><a href = '#top'>Top</a></td></tr></table>

		<br />

		<a>
		<table align = 'center'>
			<tr><td align = 'center'><span id = 'part_4'The Database Schema</span></td></tr>
			<tr><td align = 'center'>
				<object data = '$$constants{homepage_url}$$constants{flower_url}/flowers.schema.svg'></object>
			</td></tr>
		</table>

		<table align = 'center'><tr><td><a href = '#top'>Top</a></td></tr></table>
	</body>
</html>
EOS

	$file_name = "$$constants{homepage_dir}$$constants{flower_url}/$garden_name.garden.layout.html";

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(UTF-8)', $file_name);
	print $fh map{"$_\n"} @garden_index;
	close $fh;

	$self -> db -> logger -> info("Finished exporting garden layout for the '$garden_name' garden");

} # End of export_garden_layout;

# -----------------------------------------------

sub export_icons
{
	my($self)		= @_;
	my($constants)	= $self -> db -> constants;

	$self -> db -> logger -> info("flower_dir: $$constants{flower_dir}");

	my($objects) = $self -> db -> read_objects_table;

	my($color);
	my($fill, $file_name, @file_names);
	my($id, $image);
	my($name);
	my($x);
	my($y);

	for my $object (sort{$$a{name} cmp $$b{name} } @$objects)
	{
		$color		= Imager::Color -> new($$object{color}{hex});
		$fill		= Imager::Fill -> new(fg => $color, hatch => 'dots16');
		$id			= $$object{id};
		$image		= Imager -> new(xsize => $$constants{cell_width}, ysize => $$constants{cell_height});
		$name		= $$object{name};
		$file_name	= $self -> db -> clean_up_icon_name($name);

		push @file_names, [$name, $file_name];

		$image -> box(fill => $fill);
		$self -> format_string($image, $$constants{cell_width}, $$constants{cell_height}, $name);

		$image -> write(file => "$$object{icon_dir}/$file_name.png");
	}

	my(@heading)	= map{ {td => $_} } (qw(Object Icon) );
	my(@row)		= [@heading];
	my($tx)			= Text::Xslate -> new
	(
		input_layer	=> '',
		path		=> $$constants{template_path},
	);

	for my $item (@file_names)
	{
		push @row, [{td => $$item[0]}, {td => mark_raw("<object data = '$$constants{homepage_url}$$constants{icon_url}/$$item[1].png'></object>")}];
	}

	push @row, [@heading];

	$file_name = "$$constants{homepage_dir}$$constants{icon_dir}/objects.html";

	open(my $fh, '>', $file_name) || die "Can't open: $file_name: $!\n";
	print $fh $tx -> render
	(
		(
			'garden.objects.tx',
			{
				row => \@row,
			}
		)
	);

	close $fh;

	$self -> db -> logger -> info('Finished exporting all icons');

	# Return 0 for OK and 1 for error.

	return 0;

} # End of export_icons.

# -----------------------------------------------

sub export_layout_guide
{
	my($self)		= @_;
	my($constants)	= $self -> db -> constants;

	return <<EOS;
<table align='center'>
	<tr><td align='center'><span class = 'purple_on_red_title' id = 'garden_layouts'>The Garden Layouts</span></td></tr>
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/front.garden.layout.html'>The Front Garden Layout, with clickable flower thumbnails in situ</a></td></tr>
	<tr><td><br></td></tr>
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/back.garden.layout.html'>The Back Garden Layout, with clickable flower thumbnails in situ</a></td></tr>
	<tr><td><br></td></tr>
</table>
<br />
<table align='center'>
	<tr><td align='center'><br /><span class = 'purple_on_red_title' id = 'articles'>Articles</span></td></tr>
	<tr><td><a href = 'https://savage.net.au/Flowers/html/Garden.Design.Software.html'>2016-12-29: Garden Design Software</a></td></tr>
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/html/How.To.Net.Dwarf.Apples.html'>2016-01-03: How To Net Dwarf Apples</a></td></tr>
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/html/Protecting.Apples.From.Possums.html'>2013-12-08: Protecting Apples From Possums</a></td></tr>
	<tr><td><br></td></tr>
</table>
<br />
<table align='center'>
	<tr><td align='center'><br /><span class = 'purple_on_red_title' id = 'various_urls'>Various URLs</span></td></tr>
	<tr><td><a href = 'http://holt59.github.io/datatable/'>The URL</a> of the free Javascript package which manages the HTML table below</td></tr>
	<tr><td><a href = 'http://bgrins.github.io/spectrum/'>The URL</a> of the free Javascript package which provides a color picker</td></tr>
	<tr><td><br></td></tr>
	<tr><td><a href = 'http://www.theplantlist.org/'>The Plant List - A working list of all plant species</a></td></tr>
</table>
<br /><br />
EOS

} # End of export_layout_guide.

# -----------------------------------------------

sub export_layouts
{
	my($self) = @_;

	$self -> export_garden_layout('front');
	$self -> export_garden_layout('back');

} # End of export_layouts.

# -----------------------------------------------

sub flower_locations2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/flower_locations.csv/r;
	my($garden_table)			= $self -> db -> read_table('gardens');

	# Build look-up table so we can export gardens names instead of the primary keys.

	my(%gardens);

	for my $item (@$garden_table)
	{
		$gardens{$$item{id} } = $$item{name};
	}

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/common_name garden_name xy/);

	print $fh $csv -> string, "\n";

	my($common_name);
	my($garden_name);
	my(%location);

	for my $flower (@$flowers)
	{
		$common_name	= $$flower{common_name};
		%location		= ();

		for my $location (@{$$flower{flower_locations} })
		{
			$garden_name			= $gardens{$$location{garden_id} };
			$location{$garden_name}	= [] if (! $location{$garden_name});

			push @{$location{$garden_name} }, "$$location{x},$$location{y}",
		}

		for $garden_name (sort keys %location)
		{
			$csv -> combine
			(
				$common_name,
				$garden_name,
				join(' ', nsort @{$location{$garden_name} }),
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of flower_locations2csv.

# -----------------------------------------------

sub flowers2csv
{
	my($self, $csv)		= @_;
	my($flowers)		= $self -> db -> read_flowers_table;
	my($output_file)	= $self -> output_file;

	$self -> db -> logger -> info("Writing to $output_file");

	open(my $fh, '>:encoding(utf-8)', $output_file) || die "Can't open(> $output_file): $!";

	$csv -> combine(qw/common_name scientific_name aliases height width/);

	print $fh $csv -> string, "\n";

	for my $flower (@$flowers)
	{
		$csv -> combine
		(
			$$flower{common_name},
			$$flower{scientific_name},
			$$flower{aliases},
			$$flower{height},
			$$flower{width},
		);

		print $fh $csv -> string, "\n";
	}

	close($fh);

	$self -> db -> logger -> info("Wrote $output_file");

	return $flowers;

} # End of flowers2csv.

# -----------------------------------------------

sub format_string
{
	my($self, $image, $cell_width, $cell_height, $string) = @_;
	my(@words)			= split(/\s+/, $string);
	my($step_count)		= $#words + 2;
	my($vertical_step)	= int($cell_height / $step_count);
	my($y)				= 0;
	my(%vowel)			= (a => 1, e => 1, i => 1, o => 1, u => 1);

	my($after_word);
	my($finished);
	my($index);
	my(@letters);
	my($word);

	for my $step (0 .. $#words)
	{
		$y			+= $vertical_step;
		$word		= $words[$step];
		@letters	= split(//, $word);
		$index		= $#letters;
		$finished	= $index <= 7; # Don't zap the 'a' in 'a'.

		while (! $finished)
		{
			if ($vowel{$letters[$index]})
			{
				splice(@letters, $index, 1);
			}

			$index--;

			$finished = 1 if ($#letters <= 7);
		}

		$after_word = join('', @letters);

		$image -> align_string
		(
			aa		=> 1,
			font	=> $self -> title_font,
			halign	=> 'center',
			string	=> $after_word,
			x		=> int($cell_width / 2),
			y		=> $y,
		);
	}

} # End of format_string.

# -----------------------------------------------

sub gardens2csv
{
	my($self, $csv)		= @_;
	my($file_name)		= $self -> output_file =~ s/flowers.csv/gardens.csv/r;
	my($garden_table)	= $self -> db -> read_table('gardens');

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/garden_name description/);

	print $fh $csv -> string, "\n";

	my(%garden_id2name);

	for my $garden (sort{$$a{name} cmp $$b{name} } @$garden_table)
	{
		$garden_id2name{$$garden{id} } = $$garden{name};

		$csv -> combine
		(
			$$garden{name},
			$$garden{description},
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

	return \%garden_id2name;

} # End of gardens2csv.

# -----------------------------------------------

sub images2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/images.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/common_name sequence description file_name/);

	print $fh $csv -> string, "\n";

	my($common_name);

	for my $flower (@$flowers)
	{
		$common_name = $$flower{common_name};

		for my $image (sort{$$a{flower_id} cmp $$b{flower_id} || $$a{sequence} <=> $$b{sequence} } @{$$flower{images} })
		{
			$csv -> combine
			(
				$common_name,
				$$image{sequence},
				$$image{description},
				$$image{raw_name}, # We don't want the whole domain/url!
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of images2csv.

# -----------------------------------------------

sub notes2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/notes.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/common_name sequence note/);

	print $fh $csv -> string, "\n";

	my($common_name);

	for my $flower (@$flowers)
	{
		$common_name = $$flower{common_name};

		for my $note (sort{$$a{flower_id} cmp $$b{flower_id} || $$a{sequence} <=> $$b{sequence} } @{$$flower{notes} })
		{
			$csv -> combine
			(
				$common_name,
				$$note{sequence},
				$$note{note},
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of notes2csv.

# -----------------------------------------------

sub object_locations2csv
{
	my($self, $csv, $objects, $garden_id2name) = @_;
	my($file_name) = $self -> output_file =~ s/flowers.csv/object_locations.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/name garden_name xy/);

	print $fh $csv -> string, "\n";

	my($garden_id, $garden_name);
	my(%location);
	my($object_name);

	for my $object (@$objects)
	{
		%location		= ();
		$object_name	= $$object{name};

		for my $feature (@{$$object{object_locations} })
		{
			$garden_id				= $$feature{garden_id};
			$garden_name			= $$garden_id2name{$garden_id};
			$location{$garden_name}	= [] if (! $location{$garden_name});

			push @{$location{$garden_name} }, "$$feature{x},$$feature{y}";
		}

		for $garden_name (sort keys %location)
		{
			$csv -> combine
			(
				$object_name,
				$garden_name,
				join(' ', nsort @{$location{$garden_name} }),
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of object_locations2csv.

# -----------------------------------------------

sub objects2csv
{
	my($self, $csv, $color_id2hex) = @_;
	my($objects)	= $self -> db -> read_objects_table;
	my($file_name)	= $self -> output_file =~ s/flowers.csv/objects.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/name hex/);

	print $fh $csv -> string, "\n";

	for my $object (@$objects)
	{
		$csv -> combine
		(
			$$object{name},
			$$color_id2hex{$$object{color_id} },
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

	return $objects;

} # End of objects2csv.

# -----------------------------------------------

sub urls2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/urls.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/common_name sequence url/);

	print $fh $csv -> string, "\n";

	my($common_name);

	for my $flower (@$flowers)
	{
		$common_name = $$flower{common_name};

		for my $url (sort{$$a{flower_id} cmp $$b{flower_id} || $$a{sequence} <=> $$b{sequence} } @{$$flower{urls} })
		{
			$csv -> combine
			(
				$common_name,
				$$url{sequence},
				$$url{url},
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of urls2csv.

# -----------------------------------------------

1;
