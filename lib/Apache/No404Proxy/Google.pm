package Apache::No404Proxy::Google;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use WWW::Cache::Google;
use base qw(Apache::No404Proxy);

sub translate {
    my($class, $uri) = @_;
    return WWW::Cache::Google->new($uri)->as_string;
}

1;
__END__

=head1 NAME

Apache::No404Proxy::Google - Implementation of Apache::No404Proxy

=head1 SYNOPSIS

  # in httpd.conf
  PerlTransHandler Apache::No404Proxy::Google

=head1 DESCRIPTION

Apache::No404Proxy::Google is one of the implementations of
Apache::No404Proxy. This module uses WWW::Cache::Google to translate
URI to Google cache.

See L<Apache::No404Proxy/"SUBCLASSING"> for using other cache archive on
the web other than Google.

=head1 CAVEAT

See L<Apache::No404Proxy/"RESTRICTIONS FOR USE"> before using it. If
you have not done, B<DO IT NOW!>

=head1 AUTHOR

Tastuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::No404Proxy>, L<WWW::Cache::Google>

=cut
