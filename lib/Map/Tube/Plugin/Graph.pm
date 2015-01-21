package Map::Tube::Plugin::Graph;

$Map::Tube::Plugin::Graph::VERSION = '0.06';

=head1 NAME

Map::Tube::Plugin::Graph - Graph plugin for Map::Tube.

=head1 VERSION

Version 0.06

=cut

use 5.006;
use GraphViz2;
use Data::Dumper;
use MIME::Base64;
use File::Temp qw(tempfile tempdir);

use Moo;
use namespace::clean;

has 'tube'      => (is => 'rw');
has 'line'      => (is => 'rw');
has 'color'     => (is => 'rw', default  => sub { 'black' });
has 'shape'     => (is => 'rw', default  => sub { 'oval'  });
has 'directed'  => (is => 'rw', default  => sub { 1       });
has 'arrowsize' => (is => 'rw', default  => sub { 1       });
has 'labelloc'  => (is => 'rw', default  => sub { 'top'   });

=head1 DESCRIPTION

It is  a  plugin for  L<Map::Tube> to create map of individual lines. This should
not be used  directly. The support  for the plugin is defined in L<Map::Tube>. If
installed  then L<Map::Tube> should take care of it. There is a method as_image()
defined in the package L<Map::Tube>, which is just a very thin wrapper around the
plugin.

See the method as_image() defined in the package L<Map::Tube> for more details.

=head1 SYNOPSIS

    use strict; use warnings;
    use MIME::Base64;
    use Map::Tube::London;

    my $tube = Map::Tube::London->new;
    my $line = 'Jubilee';

    open(my $IMAGE, ">$line.png");
    print $IMAGE decode_base64($tube->as_image($line));
    close($IMAGE);

=head1 INSTALLATION

The plugin primarily depends on GraphViz2 library. But  the GraphViz2 can only be
installed if the perl v5.014002 is installed. If your perl  environment satisfies
this requirement then ignore the rest of instructions.

Having said that I still managed to install GraphViz2 on my box with perl 5.10.1.
It requires a  bit of nasty hack. If you are willing to do then follow the steps
below:

=over 2

=item * Download the tar ball from CPAN.
        e.g.
        wget http://search.cpan.org/CPAN/authors/id/R/RS/RSAVAGE/GraphViz2-2.34.tgz

=item * Extract the tar ball i.e. tar -xvzf GraphViz2-2.34.tgz

=item * Change directory to GraphViz2-2.34 i.e. cd GraphViz2-2.34

=item * Edit the Makefile.PL and comment the line (no: 11) that says:
        require 5.014002; # For the utf8 stuff.

=item * Now follow the usual command to make/test/install. If it complains about
        missing package then install it on demand one at a time.

=back

=head1 CONSTRUCTOR

The constructor can have the keys from the table below. You wouldn't need to know
anyway. The package L<Map::Tube> is doing everything for you.

    +-----------+----------+---------+--------------------------------------------+
    | Key       | Required | Default |  Description                               |
    +-----------+----------+---------+--------------------------------------------+
    | tube      | Yes      | -       | Object of package with the role Map::Tube. |
    | line      | Yes      | -       | Object of type Map::Tube::Line.            |
    | color     | No       | black   | Edge color outside of the Line.            |
    | shape     | No       | oval    | Node shape.                                |
    | directed  | No       | 1       | Graph direction.                           |
    | arrowsize | No       | 1       | Graph arrowsize.                           |
    | labelloc  | No       | top     | Graph label location.                      |
    +-----------+----------+---------+--------------------------------------------+

=head1 METHODS

=head2 as_image()

Returns image as base64 encoded string.

=cut

sub as_image {
    my ($self) = @_;

    die "ERROR: Key 'tube' is undefined."                               unless (defined $self->tube);
    die "ERROR: Key 'tube' expects to have taken role of Map::Tube."    unless (ref($self->tube) && $self->tube->does('Map::Tube'));
    die "ERROR: Key 'line' is undefined."                               unless (defined $self->line);
    die "ERROR: Key 'line' expects to be an object of Map::Tube::Line." unless (ref($self->line) && $self->line->isa('Map::Tube::Line'));

    my $color = 'brown';
    $color    = $self->line->color if (defined $self->line->color);
    my $line  = $self->line->name;
    my $tube  = $self->tube->name;
    my $graph = GraphViz2->new(
        edge   => { color    => $color                              },
        node   => { shape    => $self->shape                        },
        global => { directed => $self->directed                     },
        graph  => { label    => _label($line, $tube), labelloc => $self->labelloc });

    my $stations = $self->line->get_stations;

    foreach my $node (@$stations) {
        $graph->add_node(name => $node->name);
    }

    my $arrowsize = $self->arrowsize;
    my $skip      = $self->tube->skip;
    foreach my $node (@$stations) {
        my $from = $node->name;
        foreach (split /\,/,$node->link) {
            my $to = $self->tube->get_node_by_id($_);
            next if (defined $skip
                     &&
                     (exists $skip->{$line}->{$from}->{$to->name}
                      ||
                      exists $skip->{$line}->{$to->name}->{$from}));

            if (grep /$line/, (split /\,/, $to->line)) {
                $graph->add_edge(from => $from, to => $to->name, arrowsize => $arrowsize);
            }
            else {
                $graph->add_edge(from => $from, to => $to->name, arrowsize => $arrowsize, color => $self->color);
            }
        }
    }

    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $filename) = tempfile(DIR => $dir);
    $graph->run(format => 'png', output_file => "$filename");
    my $raw_string = do { local $/ = undef; <$fh>; };
    return encode_base64($raw_string);
}

#
#
# PRIVATE METHODS

sub _label {
    my ($line, $tube) = @_;

    $tube = '' unless defined $tube;
    return sprintf("%s Map: %s Line\nGenerated by Map::Tube::Plugin::Graph v%s\nTimestamp: %s",
                   $tube, $line, $Map::Tube::Plugin::Graph::VERSION, _timestamp());
}

sub _timestamp {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

=head2 tube($tube)

Sets the attribute 'tube', an object of package with the role L<Map::Tube>.

=head2 tube()

Returns the attribute 'tube'.

=head2 line($line)

Sets the attribute 'line', an object of type L<Map::Tube::Line>.

=head2 line()

Returns the attribute 'line'.

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Map-Tube-Plugin-Graph>

=head1 SEE ALSO

=over 4

=item * L<Map::Tube::GraphViz>

=item * L<Map::Metro::Graph>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube at rt.cpan.org>,  or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-Plugin-Graph>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Plugin::Graph

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-Plugin-Graph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-Plugin-Graph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-Plugin-Graph>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-Plugin-Graph/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Map::Tube::Plugin::Graph
