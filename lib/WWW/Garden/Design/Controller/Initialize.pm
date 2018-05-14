package WWW::Garden::Design::Controller::Initialize;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

use Data::Dumper::Concise; # For Dumper().

our $VERSION = '0.96';

# -----------------------------------------------

sub homepage
{
	my($self) = @_;

	$self -> app -> log -> debug('Initialize.homepage()');

	my($defaults) = $self -> app -> defaults;

	# These parameters are passed to homepage.html.ep for incorporation into JS code.

	$self -> render
	(
		attribute_elements				=> $$defaults{attribute_elements},
		constants						=> $$defaults{constants_table},
		design_garden_menu				=> $$defaults{design_garden_menu},
		design_property_menu			=> $$defaults{design_property_menu},
		features_current_feature_id		=> $$defaults{features_current_feature_id},
		feature_menu					=> $$defaults{feature_menu},
		gardens_current_garden_id		=> $$defaults{gardens_current_garden_id},
		gardens_current_property_id_1	=> $$defaults{gardens_current_property_id_1},
		gardens_current_property_id_2	=> $$defaults{properties_current_property_id},
		gardens_garden_menu				=> $$defaults{gardens_garden_menu},
		gardens_property_menu_1			=> $$defaults{gardens_property_menu_1},
		gardens_property_menu_2			=> $$defaults{gardens_property_menu_2},
		joiner							=> '«»',
		properties_current_property_id	=> $$defaults{properties_current_property_id},
		properties_property_menu		=> $$defaults{properties_property_menu},
		version							=> $VERSION,
	);

} # End of homepage.

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
