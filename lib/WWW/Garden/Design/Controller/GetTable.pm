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

sub design_object
{
	my($self)			= @_;
	my($design_object)	= $self -> param('design_object')	|| '';

	$self -> app -> log -> debug('GetTable.design_object()');

	my($defaults) = $self -> app -> defaults;

	$self -> stash(icon_name => $$defaults{db} -> get_object_by_name($design_object) );
	$self -> render;

} # End of design_object.

# -----------------------------------------------

sub objects
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.objects()');

	my($defaults)		= $self -> app -> defaults;
	my($object_table)	= $$defaults{db} -> read_objects_table;

	$self -> app -> log -> debug('GetTable.objects(). Size of object_table: ' . scalar @$object_table);
	$self -> render(json => $object_table);

} # End of objects.

# -----------------------------------------------

sub gardens
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.gardens()');

	my($defaults)		= $self -> app -> defaults;
	my($garden_table)	= $$defaults{db} -> read_gardens_table;

	$self -> app -> log -> debug('GetTable.gardens(). Size of garden_table: ' . scalar @$garden_table);
	$self -> render(json => $garden_table);

} # End of gardens.

# -----------------------------------------------

1;
