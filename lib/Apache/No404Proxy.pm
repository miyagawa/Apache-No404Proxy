package Apache::No404Proxy;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Apache::Constants qw(:response);
use LWP::UserAgent;
use URI;

sub handler($$) {
    my($class, $r) = @_;
    return DECLINED unless $r->proxyreq;
    $r->handler('perl-script');
    $r->set_handlers(PerlHandler => [ sub { $class->proxy_handler($r); } ]);
    return OK;
}

sub proxy_handler {
    my($class, $r) = @_;
    my $request = HTTP::Request->new($r->method, $r->uri);
    my %headers_in = $r->headers_in;

    while(my($key, $val) = each %headers_in) {
	$request->header($key, $val);
    }

    if ($r->method eq 'POST') {
	$request->content(scalar $r->content);
    }

    my $res = LWP::UserAgent->new->simple_request($request);
    $r->content_type($res->header('Content-type'));
    if ($res->code == 404) {
	my $cache = $class->translate($r->uri);
	# detect LOOP
	{
	    my $origuri  = URI->new($r->uri);
	    my $cacheuri = URI->new($cache);
	    if ($origuri->host eq $cacheuri->host &&
                $origuri->path eq $cacheuri->path) {
		require Apache::Log;
		$r->log->error('Apache::No404Proxy: detecting 404 loops. Stopped.');
		return NOT_FOUND;
	    }
	}

	$r->method('GET');
	$r->headers_in->unset('Content-length');
	$r->header_out(Location => $cache);
	return REDIRECT;
    }

    $r->status($res->code);
    $r->status_line($res->status_line);
    $res->scan(sub { $r->header_out(@_); });
    $r->send_http_header();
    $r->print($res->content);

    return OK;
}

sub translate {
    my($class, $uri) = @_;

    # Default to Google. Oddly enough delegating to my own child!
    require Apache::No404Proxy::Google;
    Apache::No404Proxy::Google->translate($uri);
}


1;
__END__

=head1 NAME

Apache::No404Proxy - 404 Redirecting Proxy

=head1 SYNOPSIS

  # in httpd.conf
  PerlTransHandler Apache::No404Proxy

=head1 DESCRIPTION

Oops, 404 Not found. But wait..., there is a Google cache!

Apache::No404Proxy serves as a proxy server, which automaticaly
detects 404 responses and redirects your browser to Google cache.

=head1 SUBCLASSING

Default cache archive is Google's one. Here is how you customize this.

=over 4

=item *

Declare your URL translator class.

=item *

Inherit from Apache::No404Proxy.

=item *

Define C<translate()> method.

=back

That's all. Here is an example of implementation, extracted from
Apache::No404Proxy::Google.

  package Apache::No404Proxy::Google;

  use WWW::Cache::Google;
  use base qw(Apache::No404Proxy);

  sub translate {
      my($class, $uri) = @_;
      return WWW::Cache::Google->new($uri)->as_string;
  }

Define C<translate()> method as a class method. Argument $uri is a
string that represents URI.

=head1 AUTHOR

Tastuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::ProxyPassThru>, L<LWP::UserAgent>, L<Apache::No404Proxy::Google>

=cut
