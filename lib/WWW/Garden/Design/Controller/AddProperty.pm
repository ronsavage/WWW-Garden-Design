package WWW::Garden::Design::Controller::AddProperty;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.95';

# -----------------------------------------------

sub format_message
{
	my($self, $result)		= @_;
	$$result{message}{text}	= "<h2 class = 'centered'>$$result{message}{text}</h2>";

	return $result;

} # End of format_message.

# -----------------------------------------------

sub save
{
	my($self) = @_;

	$self -> app -> log -> debug('AddProperty.save()');

	my($item) = $self -> req -> params -> to_hash;

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{name})
	{
		my($defaults)	= $self -> app -> defaults;
		my($result)		= $$defaults{db} -> process_property_submit($item);

		if ($$result{message}{type} ne 'Error')
		{
			$$result{property_table} = $$defaults{db} -> read_properties_table;
		}

		$self -> stash(json => $self -> format_message($result) );
		$self -> stash(error => undef);
	}
	else
	{
		my($message) = 'Error: The property name is mandatory';

		$self -> stash(error => $message);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of save.

# -----------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW-Garden-Design>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design>.

=head1 Author

L<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
