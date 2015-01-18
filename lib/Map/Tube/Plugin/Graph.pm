package Map::Tube::Plugin::Graph;

$Map::Tube::Plugin::Graph::VERSION = '0.01';

=head1 NAME

Map::Tube::Plugin::Graph - Graph plugin for L<Map::Tube>.

=head1 VERSION

Version 0.01

=cut

use 5.006;
use Data::Dumper;

use GraphViz2;
use Moo;
use namespace::clean;

has 'tube'     => (is => 'ro', required => 1);
has 'line'     => (is => 'ro', required => 1);
has 'color'    => (is => 'ro', default  => sub { 'black' });
has 'shape'    => (is => 'ro', default  => sub { 'oval'  });
has 'directed' => (is => 'ro', default  => sub { 1       });

=head1 METHODS

=head2 as_png()

=cut

sub as_png {
    my ($self) = @_;

    my $color = 'brown';
    $color    = $self->line->color if (defined $self->line->color);

    my $graph = GraphViz2->new(
        edge   => { color    => $color                    },
        node   => { shape    => $self->shape              },
        global => { directed => $self->directed           },
        graph  => { label    => $label, labelloc => 'top' });

    my $stations = $self->line->get_stations;

    foreach my $node (@$stations) {
        $graph->add_node(name => $node->name);
    }

    my $skip = $self->tube->skip;
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
                $graph->add_edge(from => $from, to => $to->name, arrowsize => 1);
            }
            else {
                $graph->add_edge(from => $from, to => $to->name, arrowsize => 1, color => $self->color);
            }
        }
    }

    $graph->run(format => 'png', output_file => "$line.png");
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Map-Tube-Plugin-Graph>

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
