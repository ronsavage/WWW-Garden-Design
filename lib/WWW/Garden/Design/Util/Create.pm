package WWW::Garden::Design::Util::Create;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use DBI;

use DBIx::Admin::CreateTable;

use Mojo::Log;

use Moo;

use Types::Standard qw/ArrayRef HashRef Object Str/;

extends qw/WWW::Garden::Design::Util::Config/;

has creator =>
(
	is       => 'rw',
	isa      => Object, # 'DBIx::Admin::CreateTable'.
	required => 0,
);

has dbh =>
(
	is       => 'rw',
	isa      => Object,
	required => 0,
);

has engine =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has logger =>
(
	is       => 'rw',
	isa      => Object,
	required => 0,
);

has time_option =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '0.95';

# -----------------------------------------------

sub BUILD
{
	my($self)	= @_;
	my($config)	= $self -> config;
	my($attr)	=
	{
		AutoCommit => defined($$config{AutoCommit}) ? $$config{AutoCommit} : 1,
		RaiseError => defined($$config{RaiseError}) ? $$config{RaiseError} : 1,
	};
	$$attr{sqlite_unicode} = 1 if ( ($$config{dsn} =~ /SQLite/i) && $$config{sqlite_unicode});

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

	my($log_path) = "$ENV{HOME}/perl.modules/WWW-Garden-Design/log/development.log";

	$self -> logger
	(
		Mojo::Log -> new(path => $log_path)
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
colors
constants
flowers
attribute_types
attributes
properties
gardens
flower_locations
objects
object_locations
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

sub create_colors_table
{
	my($self)        = @_;
	my($table_name)  = 'colors';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id		$primary_key,
hex		varchar(255) not null,
name	varchar(255) not null,
rgb		varchar(255) not null

) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_colors_table.

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

sub create_flower_locations_table
{
	my($self)        = @_;
	my($table_name)  = 'flower_locations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
flower_id int references flowers(id),
garden_id int references gardens(id),
x integer not null,
y integer not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_flower_locations_table.

# --------------------------------------------------

sub create_flowers_table
{
	my($self)        = @_;
	my($table_name)  = 'flowers';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
aliases			varchar(255) not null,
common_name		varchar(255) not null,
max_height		varchar(255) not null,
min_height		varchar(255) not null,
max_width		varchar(255) not null,
min_width		varchar(255) not null,
pig_latin		varchar(255) not null,
scientific_name	varchar(255) not null,
height			varchar(255) not null,
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
id $primary_key,
property_id int references properties(id),
description varchar(255) not null,
name varchar(255) not null
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
id $primary_key,
flower_id int references flowers(id),
description varchar(255) not null,
file_name varchar(255) not null,
sequence integer not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_images_table.

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
id $primary_key,
flower_id int references flowers(id),
note text not null,
sequence integer not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_notes_table.

# --------------------------------------------------

sub create_object_locations_table
{
	my($self)        = @_;
	my($table_name)  = 'object_locations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
garden_id int references gardens(id),
object_id int references objects(id),
x integer not null,
y integer not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_object_locations_table.

# --------------------------------------------------

sub create_objects_table
{
	my($self)        = @_;
	my($table_name)  = 'objects';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
color_id int references colors(id),
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'Created', $result);

}	# End of create_objects_table.

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
id $primary_key,
description varchar(255) not null,
name varchar(255) not null
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
id $primary_key,
flower_id int references flowers(id),
sequence integer not null,
url varchar(255) not null
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
object_locations
objects
flower_locations
gardens
properties
attributes
attribute_types
flowers
constants
colors
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
