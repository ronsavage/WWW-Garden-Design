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

	my($defaults)		= $self -> app -> defaults;
	my($garden_table)	= $$defaults{db} -> read_table('gardens');

	$self -> app -> log -> debug('GetTable.properties(). Size of garden_table: ' . scalar @$garden_table);
	$self -> render(json => $garden_table);

} # End of gardens.

# -----------------------------------------------

sub properties
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.properties()');

	my($defaults)		= $self -> app -> defaults;
	my($property_table)	= $$defaults{db} -> read_table('properties');

	$self -> app -> log -> debug('GetTable.properties(). Size of property_table: ' . scalar @$property_table);
	$self -> render(json => $property_table);

} # End of properties.

# -----------------------------------------------

sub switch_gardens
{
	my($self)			= @_;
	my($property_id)	= $self -> param('property_id') || 0;

	$self -> app -> log -> debug("GetTable.switch_gardens(property_id => $property_id)");

	my($defaults)		= $self -> app -> defaults;
	my($garden_table)	= $$defaults{db} -> read_table('gardens');
	my($property_table)	= $$defaults{db} -> read_table('properties');

	for my $property (@$property_table)
	{
		if ($property_id == $$property{id})
		{
			$self -> session(current_property_id			=> $$property{id});
			$self -> session(current_property_description	=> $$property{description});
			$self -> session(current_property_name			=> $$property{name});
			$self -> app -> log -> debug('Setting current_property_id => ' . $self -> session('current_property_id') );
		}
	}

	# Now select the garden with the lowest id as the current garden for this property.

	for my $garden (@$garden_table)
	{
		next if ($property_id != $$garden{property_id});

		$self -> session(current_garden_id			=> $$garden{id});
		$self -> session(current_garden_description	=> $$garden{description});
		$self -> session(current_garden_name		=> $$garden{name});
		$self -> app -> log -> debug('Setting current_garden_id => ' . $self -> session('current_garden_id') );

		last;
	}

	$self -> render;

} # End of switch_gardens.

# -----------------------------------------------

1;
