package WWW::Garden::Design::Controller::AddFlower;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use Date::Simple;

use Moo;

use URI::Find::Schemeless;

use utf8;

our $VERSION = '0.95';

# -----------------------------------------------
# https://github.com/kraih/mojo/wiki/Request-data.

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('AddFlower.display()');

	my($defaults)	= $self -> app -> defaults;
	my($validator)	= WWW::Garden::Design::Util::ValidateForm -> new;
	my($params)		= $validator -> flower_details($self, $defaults);

	if ($$params{status} == 0)
	{
#		$$defaults{db} -> add_flower($params);

		$self -> stash(error	=> undef);
		$self -> stash(details	=> $self -> format_details($params) );
	}
	else
	{
		$self -> stash(error	=> $self -> format_errors($$params{message}));
		$self -> stash(details	=> undef);
		$self -> app -> log -> error($$params{message});
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format_details
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Details.format_details(...)');

	my($html) = "<tr>\n";

	for my $name (qw/common_name scientific_name aliases height width/)
	{
		$html .= "<td class = 'generic_border'>$$item{$name}</td>\n";
	}

	$html .= "</tr>\n";

	return $html;

} # End of format_details.

# -----------------------------------------------

sub format_errors
{
	my($self, $errors) = @_;

	$self -> app -> log -> debug('Details.format_errors(...)');

	my($html) = '';

	for my $name (sort keys %$errors)
	{
		$$errors{$name}[0]	= '';
		$$errors{$name}[2]	= '';
		$html				.= <<EOS;
<tr>
	<td class = 'generic_border'>$name</td>
	<td class = 'generic_border'>$$errors{$name}[0]</td>
	<td class = 'generic_border'>$$errors{$name}[1]</td>
	<td class = 'generic_border'>$$errors{$name}[2]</td>
</tr>
EOS
	}

	return $html;

} # End of format_errors.

# -----------------------------------------------

1;
