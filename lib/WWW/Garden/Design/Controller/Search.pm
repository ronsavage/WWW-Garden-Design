package WWW::Garden::Design::Controller::Search;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use WWW::Garden::Design::Util::Config;

use Moo;

use Time::HiRes qw/gettimeofday tv_interval/;

use Types::Standard qw/Any/;

has config =>
(
	default  => sub{return WWW::Garden::Design::Util::Config -> new},
	is       => 'ro',
	isa      => Any,
	required => 0,
);

our $VERSION = '1.00';

# -----------------------------------------------

sub display
{
	my($self) 		= @_;
	my($key)  		= $self -> param('search_key') || '';
	my($start_time)	= [gettimeofday];

	$self -> app -> log -> debug("display($key)");

	if (length $key > 0)
	{
		my($defaults)				= $self -> app -> defaults;
		my($match_count, $result)	= $self -> format($$defaults{db}, $key);

		$self -> stash(elapsed_time	=> sprintf('%.2f', tv_interval($start_time) ) );
		$self -> stash(error		=> undef);
		$self -> stash(match		=> $result);
		$self -> stash(match_count	=> $match_count);
	}
	else
	{
		my($message) = 'Please supply a search key';

		$self -> stash(elapsed_time	=> 0);
		$self -> stash(error		=> $message);
		$self -> stash(match		=> undef);
		$self -> stash(match_count	=> 0);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $db, $key)	= @_;
	my($config)				= $self -> config -> config_set;
	my($result)				= $db -> search($key);
	my($count)				= 0;
	my($html)				= '';

	$db -> logger -> info('Search result: ' . Dumper($result) );

	my($attribute);
	my($native);

	for my $item (@$result)
	{
		$count++;

		# Find which of the flower's attributes is 'native'.

		for $attribute (@{$$item{attributes} })
		{
			$native = $$attribute{range} if ($$attribute{type_name} eq 'native');
		}

		# Note: Every time you add a column, you must update:
		# o templates/initialize/homepage.html.ep.
		# o templates/search/display.html.ep.

		$html .= <<EOS;
<tr>
	<td>$count</td>
	<td>$native</td>
	<td>$$item{scientific_name}</td>
	<td>$$item{common_name}</td>
	<td>$$item{aliases}</td>
	<td>$$item{hxw}</td>
	<td>
		<button class = 'button' onClick='populate_details($$item{id})'>
			<img src = '$$item{thumbnail_url}' width = '$$config{cell_width}' height = '$$config{cell_height}'/>
		</button>
	</td>
</tr>
EOS
	}

	return ($count, $html);

} # End of format.

# -----------------------------------------------

1;
