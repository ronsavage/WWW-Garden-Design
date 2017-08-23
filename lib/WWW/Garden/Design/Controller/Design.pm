package WWW::Garden::Design::Controller::Design;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

use WWW::Garden::Design::Util::ValidateForm

our $VERSION = '0.95';

# -----------------------------------------------

sub format_details
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Details.format_details(...)');

	my($html) = "<tr>\n";

	for my $name (qw/property_name garden_name/)
	{
		$html .= "<td class = 'generic_border'>$$item{$name}</td>\n";
	}

	$html .= "</tr>\n";

	return $html;

} # End of format_details.

# -----------------------------------------------

sub format_errors
{
	my($self, $params) = @_;

	$self -> app -> log -> debug('Details.format_errors(...)');

	my($html) = '';

	my($errors);

	for my $name (sort keys %{$$params{errors} })
	{
		$errors	= $$params{errors}{$name};
		$html	.= <<EOS;
<tr>
	<td class = 'generic_border'>$name</td>
	<td class = 'generic_border'>$$errors[0]</td>
	<td class = 'generic_border'>$$errors[1]</td>
	<td class = 'generic_border'>$$errors[2]</td>
</tr>
EOS
	}

	return $html;

} # End of format_errors.

# -----------------------------------------------

sub save
{
	my($self) = @_;

	$self -> app -> log -> debug('Design.save()');

	my($defaults)	= $self -> app -> defaults;
	my($validator)	= WWW::Garden::Design::Util::ValidateForm -> new;
	my($params)		= $validator -> design_details($self, $defaults);

	if ($$params{success})
	{
#		$$defaults{db} -> add_design($params);

		$self -> stash(error	=> undef);
		$self -> stash(details	=> $self -> format_details($params) );
		$self -> stash(message	=> $$params{message});
	}
	else
	{
		$self -> stash(error	=> $self -> format_errors($params) );
		$self -> stash(details	=> undef);
		$self -> stash(message	=> $$params{message});
		$self -> app -> log -> error($$params{message});
	}

	$self -> render;

} # End of save.

# -----------------------------------------------

1;
