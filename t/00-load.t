#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Map::Tube::Plugin::Graph') || print "Bail out!\n";
    use_ok('Map::Tube::Utils::Graph')  || print "Bail out!\n";
}

diag( "Testing Map::Tube::Plugin::Graph $Map::Tube::Plugin::Graph::VERSION, Perl $], $^X" );
