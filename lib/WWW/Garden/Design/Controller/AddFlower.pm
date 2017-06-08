package WWW::Garden::Design::Controller::AddFlower;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use Date::Simple;

use Moo;

use URI::Find::Schemeless;

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> app -> log -> debug('AddFlower.display()');

	my($item) =
	{
		aliases			=> $self -> param('aliases')			|| '',
		attribute_list	=> $self -> param('attribute_list')		|| '',
		common_name		=> $self -> param('common_name')		|| '',
		height			=> $self -> param('height')				|| '',
		image_list		=> $self -> param('image_list')			|| '',
		note_list		=> $self -> param('note_list')			|| '',
		scientific_name	=> $self -> param('scientific_name')	|| '',
		width			=> $self -> param('width')				|| '',
		url_list		=> $self -> param('url_list')			|| '',
	};

	$self -> app -> log -> debug("$_ => $$item{$_}") for sort keys %$item;

	if ($$item{common_name} && $$item{scientific_name})
	{
		my($defaults)	= $self -> app -> defaults;
		my($images)		= $self->process_image_list($$item{image_list});	# Hashref of arrayrefs.
		my($notes)		= {split(/!/, $$item{note_list})};					# Hashref.
		my($urls)		= $self->process_url_list($$item{url_list});		# Hashref.

#		$$defaults{db} -> add_flower($item);

		$self -> stash(error	=> undef);
		$self -> stash(details	=> $self -> format($item) );
	}
	else
	{
		my($message) = 'Missing common name or scientific name';

		$self -> stash(error	=> $message);
		$self -> stash(details	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Details.format(...)');

	my($html) = <<EOS;
<tr>
	<td>$$item{common_name}</td>
	<td>$$item{scientific_name}</td>
	<td>$$item{aliases}</td>
	<td>$$item{height}</td>
	<td>$$item{width}</td>
</tr>
EOS

	return $html;

} # End of format.

# -----------------------------------------------

sub process_image_list
{
	my($self, $image_list)	= @_;
	my(@images)				= split(/!/, $image_list);
	my($images)				= {};

	$self -> app -> log -> debug('Details.process_image_list(...)');

	for (my($i) = 0; $i <= $#images; $i += 2)
	{
		$$images{$images[$i]} = [$images[$i + 1], $images[$i + 2] ];
	}

	$self -> app -> log -> debug('Images: ' . Dumper($images) );

	return \$images;

} # End of process_image_list.

# -----------------------------------------------

sub process_url_list
{
	my($self, $url_list)	= @_;
	my($urls)				= {split(/!/, $url_list)};

	$self -> app -> log -> debug('Details.process_url_list(...)');

	for my $key (keys %$urls)
	{
		my($finder) = URI::Find::Schemeless->new(sub{my($url, $text) = @_; $$urls{$key} = $url; return $url});

		$finder->find(\$$urls{$key}) if ($$urls{$key});
	}

	$self -> app -> log -> debug('Urls: ' . Dumper($urls) );

	return $urls;

} # End of process_url_list.

# -----------------------------------------------

1;
