package WWW::Garden::Design::Util::Create;

use Moo;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use DBI;

use DBIx::Admin::CreateTable;

use Mojo::Log;

use Moo;

use Types::Standard qw/ArrayRef HashRef Object Str/;

use WWW::Garden::Design::Util::Config;

has config =>
(
	default		=> sub{WWW::Garden::Design::Util::Config -> new -> config},
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has creator =>
(
	is			=> 'rw',
	isa			=> Object, # 'DBIx::Admin::CreateTable'.
	required	=> 0,
);

has dbh =>
(
	is			=> 'rw',
	isa			=> Object,
	required	=> 0,
);

has engine =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has logger =>
(
	is			=> 'rw',
	isa			=> Object,
	required	=> 0,
);

has time_option =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

our $VERSION = '0.96';

# -----------------------------------------------

sub BUILD
{
	my($self)	= @_;
	my($config)	= $self -> config;
	my($attr)	=
	{
		AutoCommit 			=> $$config{AutoCommit},
		mysql_enable_utf8	=> $$config{mysql_enable_utf8},	#Ignored if not using MySQL.
		RaiseError 			=> $$config{RaiseError},
		sqlite_unicode		=> $$config{sqlite_unicode},	#Ignored if not using SQLite.
	};

	$self -> dbh(DBI -> connect($$config{dsn}, $$config{username}, $$config{password}, $attr) );
	$self -> dbh -> do('PRAGMA foreign_keys = ON') if ($$config{dsn} =~ /SQLite/i);

	$self -> creator
	(
		DBIx::Admin::CreateTable -> new
		(
			dbh     => $self -> dbh,
			verbose => 0,
		)
	);

	$self -> engine
	(
		$self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : ''
	);
	$self -> logger
	(
		Mojo::Log -> new(path => $$config{log_path})
	);

	$self -> time_option
	(
		$self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : ''
	);

}	# End of BUILD.

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	# Warning: The order is important.

	my($method);

	for my $table_name
(qw/
log
constants
flowers
attribute_types
attributes
properties
gardens
flower_locations
features
feature_locations
notes
images
urls
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of create_all_tables.

# --------------------------------------------------

sub create_attributes_table
{
	my($self)        = @_;
	my($table_name)  = 'attributes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id					$primary_key,
attribute_type_id	int references attribute_types(id),
flower_id			int references flowers(id),
range				varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_attributes_table.

# --------------------------------------------------

sub create_attribute_types_table
{
	my($self)        = @_;
	my($table_name)  = 'attribute_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
name		varchar(255) not null,
range		varchar(255) not null,
sequence	integer not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_attribute_types_table.

# --------------------------------------------------

sub create_constants_table
{
	my($self)        = @_;
	my($table_name)  = 'constants';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id		$primary_key,
name	varchar(255) not null,
value	varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_constants_table.

# --------------------------------------------------

sub create_feature_locations_table
{
	my($self)        = @_;
	my($table_name)  = 'feature_locations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
feature_id	int references features(id),
garden_id	int references gardens(id),
property_id	int references properties(id),
x			integer not null,
y			integer not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_feature_locations_table.

# --------------------------------------------------

sub create_features_table
{
	my($self)        = @_;
	my($table_name)  = 'features';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
hex_color	varchar(255) not null,
name		varchar(255) not null,
publish		varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_features_table.

# --------------------------------------------------

sub create_flower_locations_table
{
	my($self)        = @_;
	my($table_name)  = 'flower_locations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
flower_id 	int references flowers(id),
garden_id	int references gardens(id),
property_id	int references properties(id),
x			integer not null,
y			integer not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_flower_locations_table.

# --------------------------------------------------

sub create_flowers_table
{
	my($self)        = @_;
	my($table_name)  = 'flowers';
	my($time_option) = $self -> time_option;
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id				$primary_key,
aliases			varchar(255) not null,
common_name		varchar(255) not null,
height			varchar(255) not null,
max_height		varchar(255) not null,
max_width		varchar(255) not null,
min_height		varchar(255) not null,
min_width		varchar(255) not null,
pig_latin		varchar(255) not null,
planted			timestamp $time_option not null default current_timestamp,
publish			varchar(255) not null,
scientific_name	varchar(255) not null,
width			varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_flowers_table.

# --------------------------------------------------

sub create_gardens_table
{
	my($self)        = @_;
	my($table_name)  = 'gardens';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
property_id	int references properties(id),
description	varchar(255) not null,
name		varchar(255) not null,
publish		varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_gardens_table.

# --------------------------------------------------

sub create_images_table
{
	my($self)        = @_;
	my($table_name)  = 'images';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
flower_id	int references flowers(id),
description	varchar(255) not null,
file_name	varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_images_table.

# --------------------------------------------------
# In the log table:
# o action	=> 'add', 'delete', 'export', 'import', 'update'.
# o context	=> 'flower', etc.
# o key		=> Either 0 or a primary key associated with the context.
# o name	=> The name of the thing.
# o note	=> Any text. May contain other primary keys, e.g. when garden also has a property.
# o outcome	=> 'Success' or 'Error'.

sub create_log_table
{
	my($self)        = @_;
	my($table_name)  = 'log';
	my($time_option) = $self -> time_option;
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
action		varchar(255) not null,
context		varchar(255) not null,
file_name	varchar(255) not null,
key			integer not null,
name		varchar(255) not null,
note		text not null,
outcome		varchar(255) not null,
timestamp	timestamp $time_option not null default current_timestamp
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_log_table.

# --------------------------------------------------

sub create_notes_table
{
	my($self)        = @_;
	my($table_name)  = 'notes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
flower_id	int references flowers(id),
note		text not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_notes_table.

# --------------------------------------------------

sub create_properties_table
{
	my($self)        = @_;
	my($table_name)  = 'properties';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
description	varchar(255) not null,
name		varchar(255) not null,
publish		varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_properties_table.

# --------------------------------------------------

sub create_urls_table
{
	my($self)        = @_;
	my($table_name)  = 'urls';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
flower_id	int references flowers(id),
url			varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_urls_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	my($table_name);

	for $table_name
(qw/
urls
images
notes
feature_locations
features
flower_locations
gardens
properties
attributes
attribute_types
flowers
constants
log
/)
	{
		$self -> drop_table($table_name);
	}

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of drop_all_tables.

# -----------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	$self -> creator -> drop_table($table_name);

	$self -> report($table_name, 'Dropped', '');

} # End of drop_table.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		die "Table '$table_name' $result. \n";
	}
	else
	{
		$self -> logger -> debug("$message table '$table_name'");
	}

} # End of report.

# -----------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW-Garden-Design>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design>.

=head1 Author

L<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2018, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
