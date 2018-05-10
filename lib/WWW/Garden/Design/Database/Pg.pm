package WWW::Garden::Design::Database::Pg;

use Moo::Role;

with qw/WWW::Garden::Design::Util::Config WWW::Garden::Design::Database/;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Imager;

use Mojo::Log;
use Mojo::Pg;

our $VERSION = '0.96';

# -----------------------------------------------
# Return a list.

sub get_autocomplete_flower_list
{
	my($self, $key)	= @_;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.
	my($sql)		= "select distinct concat(scientific_name, '/', common_name) from flowers "
						. "where upper(scientific_name) like '%$key%' "
						. "or upper(common_name) like '%$key%' "
						. "or upper(aliases) like '%$key%'";

	return [$self -> db -> query($sql) -> hashes -> each];

} # End of get_autocomplete_flower_list.

# -----------------------------------------------
# Return a list.

sub get_autocomplete_feature_list
{
	my($self, $key)	= @_;
	$key			=~ s/\'/\'\'/g; # Since we're using Pg.

	return [$self -> db -> query("select distinct name from features where upper(name) like '%$key%'") -> hashes -> each];

} # End of get_autocomplete_feature_list.

# -----------------------------------------------
# Return the shortest item in the list.

sub get_autocomplete_item
{
	my($self, $context, $type, $key) = @_;
	$key =~ s/\'/\'\'/g; # Since we're using Pg.

	my(@item);
	my(@result);
	my($sql);

	for my $index (keys %$context)
	{
		my($search_column)	= $$context{$index}[0];
		my($table_name)		= $$context{$index}[1];

		# $search_column is a special case. See AutoComplete.pm and get_autocomplete_flower_list() above.

		next if ($search_column eq '*');

		# If we're not searching then we're processing the Add screen.
		# In that case, we're only interested in one $index at a time.

		if ( ($type ne 'search') && ($index ne $type) )
		{
			next;
		}

		$sql	= "select distinct $search_column from $table_name where upper($search_column) like '%$key%'";
		@item	= $self -> db -> query($sql) -> hashes -> each;

		if ($#item >= 0)
		{
			push @result, $item[0]{$search_column};
		}
	}

	my($min_length) = 99; # Arbitrary.

	my($min_value);

	for (@result)
	{
		if (length($_) < $min_length)
		{
			$min_length	= length($_);
			$min_value	= $_;
		}
	}

	if ($min_value)
	{
		$self -> logger -> info("Return <$min_value>");

		return [$min_value];
	}
	else
	{
		return [];
	}

} # End of get_autocomplete_item.

# -----------------------------------------------
# Return a list.

sub get_autocomplete_list
{
	my($self, $context, $type, $key) = @_;
	$key =~ s/\'/\'\'/g; # Since we're using Pg.

	my(@list);
	my(@result);
	my($sql, %seen);

	for my $index (keys %$context)
	{
		my($search_column)	= $$context{$index}[0];
		my($table_name)		= $$context{$index}[1];

		# $search_column is a special case. See AutoComplete.pm and get_autocomplete_flower_list() above.

		next if ($search_column eq '*');

		# If we're not searching then we're processing the Add screen.
		# In that case, we're only interested in one $index at a time.

		if ( ($type ne 'search') && ($index ne $type) )
		{
			next;
		}

		# Using 'select distinct ...' did not weed out duplicates.

		$sql	= "select $search_column from $table_name where upper($search_column) like '%$key%'";
		@list	= map{$$_[0]} $self -> db -> query($sql) -> arrays -> each;

		push @result, grep{! $seen{$_} } @list;

		$seen{$_} = 1 for @list;
	}

	return [@result];

} # End of get_autocomplete_list.

# -----------------------------------------------

sub init_db
{
	my($self) = @_;

	$self -> init_config;	# Lives in WWW::Garden::Design::Util::Config.

	my($config) = $self -> config;

	$self -> logger(Mojo::Log -> new(path => $$config{log_path}) );

	$self -> db(Mojo::Pg -> new("postgres://$$config{username}:$$config{password}\@localhost/flowers") -> db);
	$self -> init_imager;	# Lives in WWW::Garden::Design::Database. Requires db() to have been set.

}	# End of init_db.

# -----------------------------------------------

sub insert_hashref
{
	my($self, $table_name, $hashref) = @_;

	return ${$self -> db -> insert
	(
		$table_name, {map{($_ => $$hashref{$_})} keys %$hashref}, {returning => ['id']}
	) -> hash}{id};

} # End of insert_hashref.

# --------------------------------------------------

sub read_feature_dependencies
{
	my($self, $table_name, $feature_id) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> db -> query("select * from $table_name where feature_id = $feature_id") -> hashes -> each];

} # End of read_feature_dependencies.

# --------------------------------------------------

sub read_flower_dependencies
{
	my($self, $table_name, $flower_id) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> db -> query("select * from $table_name where flower_id = $flower_id") -> hashes -> each];

} # End of read_flower_dependencies.

# --------------------------------------------------

sub read_garden_dependencies
{
	my($self, $table_name, $garden_id) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> db -> query("select * from $table_name where garden_id = $garden_id") -> hashes -> each];

} # End of read_garden_dependencies.

# --------------------------------------------------

sub read_table
{
	my($self, $table_name) = @_;

	# Return an arrayref of hashrefs.

	return [$self -> db -> query("select * from $table_name") -> hashes -> each];

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
