#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use Test::More tests => 2;
use Map::Tube::Plugin::Graph;

my $graph = Map::Tube::Plugin::Graph->new;
eval { $graph->as_image; };
like($@, qr/ERROR: Key 'tube' is undefined/);

$graph->tube('dummy');
eval { $graph->as_image; };
like($@, qr/ERROR: Key 'tube' expects to have taken role of Map::Tube/);
