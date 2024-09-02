use strict; use warnings;
use Test::More;

eval {require Map::Tube::London; 1} or plan skip_all => 'no Map::Tube::London';

my $tube = Map::Tube::London->new;
eval { $tube->as_image; };
is $@, '';

eval { $tube->as_image('Bakerloo'); };
is $@, '';

eval { $tube->as_png('Bakerloo'); };
is $@, '';

done_testing;
