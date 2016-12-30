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
	my($self)		= @_;
	my($defaults)	= $self -> app -> defaults;
	my($ids)		= $$defaults{search_attribute_ids};
	my(%keys)		= map{($_ => ($self -> param($_) || '') )} map{@$_} @$ids;
	my($key)		= $self -> param('search_key');

	$self -> app -> log -> debug('body_params: ' . Dumper($self -> res -> body_params -> to_hash) );
	$self -> app -> log -> debug("search keys: '$key' and \n" . Dumper(\%keys) );

	if (length $key > 0)
	{
		my($defaults)							= $self -> app -> defaults;
		my($time_taken, $match_count, $result)	= $self -> format($$defaults{db}, $key);

		$self -> stash(elapsed_time	=> sprintf('%.2f', $time_taken) );
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
	my($constants)			= $db -> read_constants_table;
	my($count)				= 0;
	my($html)				= '';
	my($start_time)			= [gettimeofday];
	my($result)				= $db -> search($key);
	my($time_taken)			= tv_interval($start_time);

	my($attribute);
	my($native);

	for my $item (@$result)
	{
		$count++;

		# Find which of the flower's attributes is 'native'.

		for $attribute (@{$$item{attributes} })
		{
			$native = $$attribute{range} if ($$attribute{name} eq 'native');
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
			<img src = '$$item{thumbnail_url}' width = '$$constants{cell_width}' height = '$$constants{cell_height}'/>
		</button>
	</td>
</tr>
EOS
	}

	return ($time_taken, $count, $html);

} # End of format.

# -----------------------------------------------

1;
