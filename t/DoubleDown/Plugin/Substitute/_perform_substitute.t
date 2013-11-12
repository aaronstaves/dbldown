#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;    # tests => ?;

use DoubleDown::Plugin::Substitute;

use DoubleDown::Core;
use DoubleDown::IRC::Message;

my $sub_plugin = DoubleDown::Plugin::Substitute->new();
my $core       = DoubleDown::Core->instance;

my $channel = 'test';
my $nick    = 'test';

my @tests = (
	{
		last     => 'test message',
		expected => 'TEST message',
		message  => {
			channel => $channel,
			irc_msg => {},
			nick    => $nick,
			text    => 's/test/TEST/',
		}
	},
	{
		last     => 'test message',
		expected => 'text message',
		message  => {
			channel => $channel,
			irc_msg => {},
			nick    => $nick,
			text    => 's/s/x/',
		}
	},
	{
		last     => 'test message',
		expected => 'texxt message',
		message  => {
			channel => $channel,
			irc_msg => {},
			nick    => $nick,
			text    => 's/s/xx/',
		}
	},
	{
		last     => 'test message',
		expected => 'text mexxage',
		message  => {
			channel => $channel,
			irc_msg => {},
			nick    => $nick,
			text    => 's/s/x/g',
		}
	},
	{
		last     => 'Test Message',
		expected => 'Tesx Message',
		message  => {
			channel => $channel,
			irc_msg => {},
			nick    => $nick,
			text    => 's/t/x/g',
		}
	},
	{
		last     => 'Test Message',
		expected => 'xesx Message',
		message  => {
			channel => $channel,
			irc_msg => {},
			nick    => $nick,
			text    => 's/t/x/gi',
		}
	},
	{
		last     => 'test message',
		expected => 'TEST message',
		message  => {
			channel => $channel,
			irc_msg => {},
			nick    => $nick,
			text    => $nick . ' s/test/TEST/',
		}
	},
	{
		last     => 'this is/was my message',
		expected => q{this wasn't my message},
		message  => {
			channel => $channel,
			irc_msg => {},
			nick    => $nick,
			text    => q{s/is\/was/wasn't/g},
		}
	},
);

foreach my $test_r (@tests) {
	$core->stash->{last_msg}->{$channel}->{$nick} = $test_r->{last};
	my $message = DoubleDown::IRC::Message->new( $test_r->{message} );

	my ( $fixed, $user ) = $sub_plugin->_perform_substitution($message);
	is $fixed, $test_r->{expected}, 'Message looks right';
}

done_testing();

