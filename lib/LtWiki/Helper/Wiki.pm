package LtWiki::Helper::Wiki;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

sub register {
	my ($self, $app) = @_;
	
	$app->helper( wiki_url_for =>
		sub {
			my $self = shift;
			my $url = shift;

		}
	);
}

1;