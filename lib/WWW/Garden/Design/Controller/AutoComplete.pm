package WWW::Garden::Design::Controller::AutoComplete;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self)	= @_;
	my($key)	= $self -> param('term')	|| ''; # jquery forces use of 'term'.
	my($type)	= $self -> param('type')	|| '';

	$self -> app -> log -> debug("AutoComplete.display(key: $key, type: $type)");

	my(%context) =
	(	# Form field		Table column		Table name.
		aliases			=> ['aliases',			'flowers'],
		common_name		=> ['common_name',		'flowers'],
		design_flower	=> ['*',				'flowers'],
		design_object	=> ['*',				'objects'],
		garden_name		=> ['name',				'gardens'],
		object_name		=> ['name',				'objects'],
		property_name	=> ['name',				'properties'],
		scientific_name	=> ['scientific_name',	'flowers'],
	);
	my(%want_single_item) =
	(
		garden_name		=> 1,
		property_name	=> 1,
	);

	my($defaults) = $self -> app -> defaults;

	# In the case of $type being 'design_flower', we're called from line 501 in homepage.html.ep,
	# meaning we're on the Design garden tab. In this case we can't assume the string the user typed
	# petains to just one column of the flower database, so we search every several columns in the
	# 'flowers' table: scientific_name, common_name and aliases.
	# Warning: This use '*' in %context above means the methods in Database.pm which search %context
	# must skip it. See Database.get_autocomplete_item() and Database.get_autocomplete_list().
	# Likewise for 'design_object'.

	if ($type eq 'design_flower')
	{
		$self -> render(json => $$defaults{db} -> get_autocomplete_flower_list(uc $key) );
	}
	elsif ($type eq 'design_object')
	{
		$self -> render(json => $$defaults{db} -> get_autocomplete_object_list(uc $key) );
	}
	elsif ($want_single_item{$type})
	{
		$self -> render(json => $$defaults{db} -> get_autocomplete_item(\%context, $type, uc $key) );
	}
	else
	{
		$self -> render(json => $$defaults{db} -> get_autocomplete_list(\%context, $type, uc $key) );
	}

} # End of display.

# -----------------------------------------------

1;
