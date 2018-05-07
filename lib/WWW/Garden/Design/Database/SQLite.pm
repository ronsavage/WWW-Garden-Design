package WWW::Garden::Design::Database::SQLite;

use boolean;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use DBI;

use FindBin;

use Imager;
use Imager::Fill;

use Lingua::EN::Inflect qw/inflect PL_N/; # PL_N: plural of a singular noun.

use Moo;

use Text::CSV::Encoded;

use Time::HiRes qw/gettimeofday tv_interval/;

use Types::Standard qw/Object/;

use Unicode::Collate;

extends 'WWW::Garden::Design::Database';

has dbh =>
(
	is			=> 'rw',
	isa			=> Object,
	required	=> 0,
);

our $VERSION = '0.96';

# -----------------------------------------------

sub BUILD
{
	my($self)  	= @_;
	my($config)	= $self -> config;

	my(%attributes) =
	(
		AutoCommit 			=> $$config{AutoCommit},
		mysql_enable_utf8	=> $$config{mysql_enable_utf8},	#Ignored if not using MySQL.
		RaiseError 			=> $$config{RaiseError},
		sqlite_unicode		=> $$config{sqlite_unicode},	#Ignored if not using SQLite.
	);

	$self -> dbh(DBI -> connect($$config{dsn}, $$config{username}, $$config{password}, \%attributes) );

}	# End of BUILD.

# --------------------------------------------------

sub get_flower_by_both_names
{
	my($self, $key)	= @_;
	my($constants)	= $self -> constants;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.
	$key			= uc $key;
	my(@key)		= split('/', $key);
	my($sql)		= "select pig_latin from flowers where upper(scientific_name) like ? and upper(common_name) like ?";
	my(@result)		= $self -> pg -> query($sql, $key[0], $key[1]) -> hashes;
	my($pig_latin)	= $#result >= 0 ? "$$constants{homepage_url}$$constants{image_url}/$result[0].0.jpg" : '';

	return $pig_latin;

} # End of get_flower_by_both_names.

# --------------------------------------------------

sub get_flower_by_id
{
	my($self, $flower_id)		= @_;
	my($attribute_types_table)	= $self -> read_table('attribute_types');
	my($sql)					= "select * from flowers where id = $flower_id";
	my($query)					= $self -> pg -> query($sql);
	my($flower)					= $query -> hash;

	$query -> finish;

	my(%attribute_type);

	for (@$attribute_types_table)
	{
		$attribute_type{$$_{id} } = $_;
	}

	for my $table_name (qw/attributes flower_locations images notes urls/)
	{
		# Return an arrayref of hashrefs.

		$$flower{$table_name} = $self -> read_flower_dependencies($table_name, $$flower{id});
	}

	my($attribute);
	my($id);

	# Annotate the attributes with their types.

	for my $i (0 .. $#{$$flower{attributes} })
	{
		$attribute	= $$flower{attributes}[$i];
		$id			= $$attribute{attribute_type_id};

		for my $name (qw/name sequence/)
		{
			$$flower{attributes}[$i]{$name} = $attribute_type{$id}{$name};
		}
	}

	# Return a hashref.

	return $flower;

} # End of get_flower_by_id.

# --------------------------------------------------

sub get_feature_by_name
{
	my($self, $key)	= @_;
	my($constants)	= $self -> constants;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.
	$key			= "\U%$key"; # \U => Convert to upper-case.
	my($sql)		= "select name from features where upper(name) like ?";
	my(@result)		= $self -> pg -> query($sql, $key) -> hashes;
	my($icon_name)	= $self -> clean_up_icon_name($result[0]);
	$icon_name		= length($icon_name) > 0 ? "$$constants{homepage_url}$$constants{icon_url}/$icon_name.png" : '';

	return $icon_name;

} # End of get_feature_by_name.

# -----------------------------------------------

sub insert_hashref
{
	my($self, $table_name, $hashref) = @_;

	return ${$self -> pg -> insert
	(
		$table_name, {map{($_ => $$hashref{$_})} keys %$hashref}, {returning => ['id']}
	) -> hash}{id};

} # End of insert_hashref.

# --------------------------------------------------

sub read_flower_dependencies
{
	my($self, $table_name, $flower_id) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> pg -> query("select * from $table_name where flower_id = $flower_id") -> hashes -> each];

} # End of read_flower_dependencies.

# --------------------------------------------------

sub read_garden_dependencies
{
	my($self, $table_name, $garden_id) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> pg -> query("select * from $table_name where garden_id = $garden_id") -> hashes -> each];

} # End of read_garden_dependencies.

# --------------------------------------------------

sub read_feature_dependencies
{
	my($self, $table_name, $feature_id) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> pg -> query("select * from $table_name where feature_id = $feature_id") -> hashes -> each];

} # End of read_feature_dependencies.

# --------------------------------------------------

sub read_properties_table
{
	my($self)		= @_;
	my($constants)	= $self -> constants;

	# Return an arrayref of hashrefs.

	return [sort{$$a{name} cmp $$b{name} } @{$self -> read_table('properties')}];

} # End of read_properties_table.

# --------------------------------------------------

sub read_table
{
	my($self, $table_name) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> pg -> query("select * from $table_name") -> hashes -> each];

} # End of read_table.

# --------------------------------------------------

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

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
