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

sub design_flower
{
	my($self)			= @_;
	my($design_flower)	= $self -> param('design_flower') || '';

	$self -> app -> log -> debug('GetTable.design_flower()');

	if (length($design_flower) < 2)
	{
		$self -> stash(thumbnail_name => '');
		$self -> render();
	}
	else
	{
		my($defaults) = $self -> app -> defaults;

		$self -> stash(thumbnail_name => $$defaults{db} -> get_flower_by_both_names($design_flower) );
		$self -> render;
	}

} # End of design_flower.

# -----------------------------------------------

sub design_object
{
	my($self)			= @_;
	my($design_object)	= $self -> param('design_object') || '';

	$self -> app -> log -> debug('GetTable.design_object()');

	if (length($design_object) < 2)
	{
		$self -> stash(icon_name => '');
		$self -> render();
	}
	else
	{
		my($defaults) = $self -> app -> defaults;

		$self -> stash(icon_name => $$defaults{db} -> get_object_by_name($design_object) );
		$self -> render;
	}

} # End of design_object.

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

sub properties
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.properties()');

	my($defaults)		= $self -> app -> defaults;
	my($property_table)	= $$defaults{db} -> read_properties_table;

	$self -> app -> log -> debug('GetTable.properties(). Size of property_table: ' . scalar @$property_table);
	$self -> render(json => $property_table);

} # End of properties.

# -----------------------------------------------

1;
