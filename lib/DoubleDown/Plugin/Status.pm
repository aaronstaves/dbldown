=pod

ABSTRACT: Status functions

=cut
package DoubleDown::Plugin::Status;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;

use String::Util 'trim';
use Net::OpenSSH;
use String::IRC;

has commands => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_commands'
);

sub _build_commands {

  return {
    '^status (.+)$$' => 'process',
  }
}


=head1 Commands

=over 2

=item status <server>

Displays status of a specific server

=cut
sub process {

	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = DoubleDown::Core->_config;
	my $channel = $message->channel;
	my $server = $message->parts->[-1];

	my $servers = $config->{servers};


	if ( !defined $servers->{ $server} ) {
		die ( "Unknown server $server" );
	}

	my $server_info = $servers->{ $server };
	my $ssh = Net::OpenSSH->new( $server_info->{host} );

	# Branch name
	my @result = $ssh->capture(sprintf 'git --git-dir=%s rev-parse --abbrev-ref HEAD', $server_info->{git_dir} );
	my $branch = trim $result[0];

	@result = $ssh->capture(sprintf 'git --git-dir=%s log -n1 --format="%%H"', $server_info->{git_dir} );
	my $sha = trim $result[0];
	$core->debug( message => "found branch $branch on $sha", color => $core->debug_yellow);
	$core->irc->_con->send_msg( undef, PRIVMSG => $channel, String::IRC->new("$server is running $sha on $branch")->yellow('black') );

	@result = $ssh->capture(sprintf 'git --git-dir=%s log -n1 --format="%%an committed %%cr: %%s"', $server_info->{git_dir} );
	my $commit = trim $result[0];
	$core->debug( message => "found commit $commit", color => $core->debug_yellow);
	$core->irc->_con->send_msg( undef, PRIVMSG => $channel, String::IRC->new($commit)->yellow('black') );

}

1;

