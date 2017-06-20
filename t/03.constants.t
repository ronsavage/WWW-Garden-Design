#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use FindBin;

use Mojolicious::Validator;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;
use WWW::Garden::Design::Util::Validator;

# ------------------------------------------------

sub test_attribute_types
{
	my($filer, $checker, $test_count, $expected_constants) = @_;
	my($path)		= "$FindBin::Bin/../data/flowers.csv";
	my($table_name)	= 'constants';
	$path			=~ s/flowers/$table_name/;
	my($constants)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in constants.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort(qw/name value/);
	my(@got_headings)		= sort keys %{$$constants[0]};

	my($result);

	for my $i (0 .. $#expected_headings)
	{
		$result = $checker -> check_equal_to
					(
						{expected => $expected_headings[$i], got => $got_headings[$i]},
						'got',
						'expected'
					);

		ok($result == 1, "Heading '$expected_headings[$i]' ok"); $test_count++;
	}

	# 2: Validate the data in constants.csv.

	my($expected_keys) = [keys %$expected_constants];

	my($expected_format);
	my($name);
	my(%required);
	my($value);

	@required{@$expected_keys} = 0 x @$expected_keys;

	for my $params (@$constants)
	{
		$name				= $$params{name};
		$value				= $$params{value};
		$expected_format	= $$expected_constants{$name};
		$required{$name}	= 1;

		$result = $checker -> check_member($params, 'name', $expected_keys);

		ok($result == 1, "Constant '$name' ok"); $test_count++;

		if ($expected_format eq 'Integer')
		{
			ok($checker -> check_natural_number($params, 'value') == 1, "Constant '$value' ok"); $test_count++;
		}
		else
		{
			ok(length($value) > 0, "Constant '$value' ok"); $test_count++;
		}
	}

	for $name (sort @$expected_keys)
	{
		ok($checker -> check_count(\%required, $name, 1) == 1, "Name '$name' not duplicated and not missing"); $test_count++;
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
my($checker)	= WWW::Garden::Design::Util::Validator -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_attribute_types($filer, $checker, $test_count, $expected_constants);

print "# Internal test count: $test_count\n";

done_testing($test_count);
