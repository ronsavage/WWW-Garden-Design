package WWW::Garden::Design::Controller::GetTable;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub attribute_types
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.attribute_types()');

	my($defaults) = $self -> app -> defaults;

	$self -> render(json => $$defaults{db} -> read_table('attribute_types') );

} # End of attribute_types.

# -----------------------------------------------

sub gardens
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.gardens()');

	my($defaults) = $self -> app -> defaults;

	$self -> render(json => $$defaults{db} -> read_table('gardens') );

} # End of gardens.

# -----------------------------------------------

sub properties
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.properties()');

	my($defaults) = $self -> app -> defaults;

	$self -> render(json => $$defaults{db} -> read_table('properties') );

} # End of properties.

# -----------------------------------------------

1;
