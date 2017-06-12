#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Mojolicious::Validator;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_attribute_types
{
	my($filer, $validator, $validation, $test_count, $expected_constants) = @_;
	my($path)				= "$FindBin::Bin/../data/flowers.csv";
	my($table_name)			= 'constants';
	$path					=~ s/flowers/$table_name/;
	my($constants)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in constants.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort('name', 'value');
	my(@got_headings)		= sort keys %{$$constants[0]};

	my($result);

	for my $i (0 .. $#expected_headings)
	{
		$result = $validation
		-> input({expected => $expected_headings[$i], got => $got_headings[$i]})
		-> required('got')
		-> equal_to('expected')
		-> is_valid;

		ok($result == 1, "Heading '$expected_headings[$i]' ok"); $test_count++;
	}

	# 2: Validate the data in constants.csv.

	my($expected_format);
	my($name);
	my($value);

	for my $line (@$constants)
	{
		$name				= $$line{name};
		$value				= $$line{value};
		$expected_format	= $$expected_constants{$name};

		ok($expected_format, "Constant '$name'"); $test_count++;

		if (! $expected_format)
		{
			BAIL_OUT('No point continuing when the above test fails');
		}

		if ($expected_format eq 'Integer')
		{
			ok($value =~ /^[0-9]{1,3}$/, "Constant '$value' ok"); $test_count++;
		}
		else
		{
			ok(length($value) > 0, "Constant '$value' ok"); $test_count++;
		}
	}

	return $test_count;

} # End of test_attribute_types.

# ------------------------------------------------

my($expected_constants) =
{
	cell_height				=> 'Integer',
	cell_width				=> 'Integer',
	css_class4headings		=> 'black_on_reddish_title',
	design_thumbnail_size	=> 'Integer',
	detail_thumbnail_size	=> 'Integer',
	flower_dir				=> '/Flowers',
	flower_url				=> '/Flowers',
	flower_url4js			=> '/Flowers',
	height_latitude			=> 'Integer',
	homepage_dir			=> '/home/ron/savage.net.au',
	homepage_url			=> 'http://127.0.0.1',
	homepage_url4js			=> 'http://127.0.0.1',
	icon_dir				=> '/Flowers/icons',
	icon_url				=> '/Flowers/icons',
	icon_url4js				=> '/Flowers/icons',
	image_dir				=> '/Flowers/images',
	image_url				=> '/Flowers/images',
	image_url4js			=> '/Flowers/images',
	max_image_count			=> 'Integer',
	max_note_count			=> 'Integer',
	max_url_count			=> 'Integer',
	search_thumbnail_size	=> 'Integer',
	template_path			=> '/home/ron/perl.modules/WWW-Garden-Design/public/assets/templates/www/garden/design',
	virtual_cell_count		=> 'Integer',
	virtual_cell_size		=> 'Integer',
	width_latitude			=> 'Integer',
	x_offset				=> 'Integer',
	y_offset				=> 'Integer',
};
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
my($validator)	= Mojolicious::Validator -> new;
my($validation)	= $validator -> validation;
$test_count		= test_attribute_types($filer, $validator, $validation, $test_count, $expected_constants);

print "# Internal test count: $test_count\n";

done_testing($test_count);
