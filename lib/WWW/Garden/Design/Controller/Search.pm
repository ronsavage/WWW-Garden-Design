package WWW::Garden::Design::Controller::Search;

use Mojo::Base 'Mojolicious::Controller';

use boolean;

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

our $VERSION = '0.95';

# -----------------------------------------------

sub display
{
	my($self)				= @_;
	my($csrf_token)			= $self -> param('csrf_token')	|| '';
	my($search_text)		= $self -> param('search_text')	|| '';
	$search_text			=~ s/^\s+//;
	$search_text			=~ s/\s+$//;
	my($defaults)			= $self -> app -> defaults;
	my($ids)				= $$defaults{search_attribute_ids};
	my(%search_attributes)	= map{($_ => ($self -> param($_) || '') )} map{@$_} @$ids;
	my($must_have)			= $search_text . join('', values %search_attributes);

	if (length $must_have > 0)
	{
		my($attributes_table)				= $$defaults{attributes_table};
		my($attribute_types_table)			= $$defaults{attribute_types_table};
		my($constants_table)				= $$defaults{constants_table};
		my($db)								= $$defaults{db};
		my($search_attributes)				= $self -> extract_attributes(\%search_attributes);
		my($start_time)						= [gettimeofday];
		my($search_results, $text_is_clean)	= $db -> search($attributes_table, $attribute_types_table, $constants_table, $search_attributes, $search_text);
		my($time_taken)						= tv_interval($start_time);
		my($match_count)					= 0;
		my($result_html)					= '';

		if ($text_is_clean -> isTrue)
		{
			($match_count, $result_html) = $self -> format($constants_table, $db, $search_results);
		}

		$self -> stash(elapsed_time	=> sprintf('%.2f', $time_taken) );
		$self -> stash(error		=> undef);
		$self -> stash(match_count	=> $match_count);
		$self -> stash(result_html	=> $result_html);
	}
	else
	{
		my($message) = 'Please supply some search text or select some attributes';

		$self -> stash(elapsed_time	=> 0);
		$self -> stash(error		=> $message);
		$self -> stash(match_count	=> 0);
		$self -> stash(result_html	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub extract_attributes
{
	my($self, $search_attributes)	= @_;
	my($defaults)					= $self -> app -> defaults;
	my($attribute_type_names)		= $$defaults{attribute_type_names};
	my($attribute_type_fields)		= $$defaults{attribute_type_fields};

	my($attribute_name, $attribute_value);
	my($name);
	my(%result);

	# Ensure every checkbox has a value of 'true' and a name like:
	# 'A known attribute type' . '_' . 'A value',
	# where the value is one of the known values for the given type.

	for my $key (keys %$search_attributes)
	{
		# Strip off the leading 'search_'.

		next if (substr($key, 0, 7) ne 'search_');

		$name = substr($key, 7);

		next if ($$search_attributes{$key} ne 'true');

		for my $type_name (@$attribute_type_names)
		{
			if ($name =~ /^($type_name)_(.+)$/)
			{
				# Warning: Because of the s/// you cannot combine these into 1 line
				# such as $result{$1} = $2 =~ s/_/ /gr. I know - I tried.

				$attribute_name		= $1;
				$attribute_value	= $2;
				$attribute_value	=~ s/_/ /g;

				for my $type_value (@{$$attribute_type_fields{$type_name} })
				{
					$result{$attribute_name} = $attribute_value if ($attribute_value eq $type_value);
				}
			}
		}
	}

	return \%result;

} # End of extract_attributes.

# -----------------------------------------------

sub format
{
	my($self, $constants_table, $db, $search_results) = @_;
	my($count)	= 0;
	my($html)	= '';

	my($attribute);
	my($native);

	for my $item (@$search_results)
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
			<img src = '$$item{thumbnail_url}' width = '$$constants_table{cell_width}' height = '$$constants_table{cell_height}'/>
		</button>
	</td>
</tr>
EOS
	}

	return ($count, $html);

} # End of format.

# -----------------------------------------------

1;
