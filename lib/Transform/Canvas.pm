package Transform::Canvas;

use 5.008;
use strict;
use warnings;
use Carp;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Transform::Canvas ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our $VERSION = '0.005';
$VERSION = eval $VERSION;    # see L<perlmodstyle>

=head1 NAME

Transform::Canvas - Perl extension for performing Coordinate transformation 
operations from the cartesion to the canvas coordinate systems.

=head1 SYNOPSIS

  use Transform::Canvas;
  #create a mapping transform for data from 
  #x=-100,y=-100,x=100,y=100  to x=10,y=10,x=100,y=100
  $t = Transform::Canvas->new(canvas=>[10,10,100,100],data=>[-100,-100,100,100]);
  #reate a arrays of x and y values
  $r_x = [-100,-10, 0, 20, 40, 60, 80, 100];
  $r_y = [-100,-10, 0, 20, 40, 60, 80, 100];
  #map the two arrays into the canvas data space
  ($pr_x,$pr_y) = $t->map($r_x,$r_y);

=head1 DESCRIPTION

Transform::Canvas is a module which automates reference-frame transformations beween two cartesian coordinate systems. it is specifically intended to be used as a facilitator for coordinate-system transformation procedures between the traditional, right-hand-rule coordinate system used in mathematics graphing and the visual-arts coordinate system with a y-axis pointing down. 

The module allows for arbitrary 2-D transform mappings.

=head1 Methods

=head2 sub new (canvas => [x0 y0 x1 y1], data=>[x0 y0 x1 y1])

generate the conversion object through which all data points will be passed.
NB: svg drawings use the painter's model and use a coordinate system which
starts at the top, left corner of the document and has x-axis increasing to
the right and y-axis increasing down.

In certain drawings, the y-axis is inverted compared to mathematical 
representation systems which prefer y to increase in the upwards direction.

 canvas (target):
        x0 = paper-space minimum x value
        y0 = paper-space maximum x value
        x1 = paper-space minimum y value
        y1 = paper-space maximum y value
 data (source):
        x0 = data-space minimum x value
        y0 = data--space maximum x value
        x1 = data-space minimum y value
        y1 = data-space maximum y value

=cut

sub new ($;@) {
    my ( $proto, %attrs ) = @_;
    my $class = ref $proto || $proto;
    my $self;
    $self->{_config_} = {};

    #define the mappings
    $self->{_config_} = \%attrs;

    confess("Mising canvas data")
      unless scalar( @{ $self->{_config_}->{canvas} } ) == 4;
    confess("Mising data data")
      unless scalar( @{ $self->{_config_}->{data} } ) == 4;

    # establish defaults for unspecified attributes
    bless $self, $class;
    $self->initialize()
      || croak("Failed to initialize Transform::Canvas object");
    $self->prepareMap() || croak("Failed to prepare transformation map");

    return $self;
}

sub initialize ($) {
    my $self = shift;
}

=head2 prepareMap

Prepare the transformation space for the conversions;
Currently only handles linear transformations, but this is a perfect candidate
for non-spacial, non-cartesian transforms... 

=cut

sub prepareMap ($;@) {
    my $self = shift;

    #scale factors

    #flip
    #scale
    #translate (?)
    my $sy = ( $self->cy1 - $self->cy0 ) / ( $self->dy1 - $self->dy0 );    #ok
    my $sx = ( $self->cx1 - $self->cx0 ) / ( $self->dx1 - $self->dx0 );    #ok

    #translation factors
    my $tx = $self->cx0;
    my $ty = $self->cy0;

    $self->{map} = {
        x => {
            s => $sx,
            t => $tx,
        },
        y => {
            s => $sy,
            t => $ty,
        },
    };

}

# helper methods which return the corners of the canvas and data windows

=head2 sub cx0

return the canvas x min value

=head2 sub cx1

return the canvas x max value

=head2 sub cy0

return the canvas y min value

=head2 sub cy1

return the canvas y max value

=head2 sub dx0

return the data space x min value

=head2 sub dx1

return the data space x max value

=head2 sub dy0

return the data space y min value

=head2 sub dy1

return the data space y max value


=cut 

sub cx0 ($;$) {
    my $self = shift;
    confess("canvas min x value not set")
      unless defined $self->{_config_}->{canvas}->[0];

    return $self->{_config_}->{canvas}->[0];
}


sub cx1 ($;$) {
    my $self = shift;
    confess("canvas max x value not set")
      unless defined $self->{_config_}->{canvas}->[2];
    return $self->{_config_}->{canvas}->[2];
}

sub dx0 ($;$) {
    my $self = shift;
    confess("data min x value not set")
      unless defined $self->{_config_}->{data}->[0];
    return $self->{_config_}->{data}->[0];
}

sub dx1 ($;$) {
    my $self = shift;
    confess("data max x value not set")
      unless defined $self->{_config_}->{data}->[2];
    return $self->{_config_}->{data}->[2];
}

sub cy0 ($;$) {
    my $self = shift;
    confess("canvas min y value not set")
      unless defined $self->{_config_}->{canvas}->[1];
    return $self->{_config_}->{canvas}->[1];
}

sub cy1 ($;$) {
    my $self = shift;
    confess("canvas max y value not set")
      unless defined $self->{_config_}->{canvas}->[3];
    return $self->{_config_}->{canvas}->[3];
}

sub dy0 ($;$) {
    my $self = shift;
    confess("datamin y value not set")
      unless defined $self->{_config_}->{data}->[1];
    return $self->{_config_}->{data}->[1];
}

sub dy1 ($;$) {
    my $self = shift;
    confess("data max y value not set")
      unless defined $self->{_config_}->{data}->[3];
    return $self->{_config_}->{data}->[3];
}

=head2 map($x,$y)

Map an array or a value from the (x,y) data axes to the (x,y) canvas axes

=cut

sub map ($$$) {
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    croak "map error: x is undefined" unless defined $x;
    croak "map error: y is undefined" unless defined $y;

    #be flexible about single values or array refs
    $x = [$x] unless ref($x) eq 'ARRAY';
    $y = [$y] unless ref($y) eq 'ARRAY';
    croak "Error: x and y arrays different lengths"
      unless ( scalar @$x == scalar @$y );

    my @p_x = map {
        ( ( $_ - $self->dx0 ) * $self->{map}->{x}->{s} ) +
          $self->{map}->{x}->{t}
    } @$x;
    my @p_y = map {
        ( ( $self->dy1 - $_ ) * $self->{map}->{y}->{s} ) +
          $self->{map}->{y}->{t}
    } @$y;

    return ( \@p_x, \@p_y );
}

=head2 mapX

Map an array or a value of the x data axis to the x canvas axis

=cut

sub mapX ($$) {
    my $self = shift;
    my $x    = shift;
    croak "x is undefined" unless defined $x;

    #be flexible about single values or array refs
    $x = [$x] unless ref($x) eq 'ARRAY';

    my @p_x = map {
        ( ( $_ - $self->dx0 ) * $self->{map}->{x}->{s} ) +
          $self->{map}->{x}->{t}
    } @$x;
    return $p_x[0] if scalar @p_x == 1;
    return ( \@p_x );
}

=head2 mapY

Map an array or a value of the y data axis to the y canvas axis

=cut

sub mapY ($$) {
    my $self = shift;
    my $y    = shift;
    croak "y is undefined" unless defined $y;

    #be flexible about single values or array refs
    $y = [$y] unless ref($y) eq 'ARRAY';
    my @p_y = map {
        ( ( $self->dy1 - $_ ) * $self->{map}->{y}->{s} ) +
          $self->{map}->{y}->{t}
    } @$y;
    return $p_y[0] if scalar @p_y == 1;
    return ( \@p_y );
}

=head1 SEE ALSO

SVG SVG::Parser SVG::DOM SVG::Element SVG::Graph SVG::Extension

=head1 AUTHOR

Ronan Oger, E<lt>ronan@roasp.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ronan Oger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=head2 DEDICATION

This module's POD is dedicated to Adam Kennedy. I have little patience for rudeness and ignorance. Adam seems to show a past and current talent for both.

As a coder, he may have considered the emotional attachement people have with what they write. Although his review was fairly pointless and clearly so, this guy seems to make a habit of it. He needs to be kept accountable.

If this moppet had shown the slightest decency and had dropped me an email about the issue (I'm not hard to find), I may have addressed his fairly trivial concerns. Instead he decided to throw a lasting comment in an inappropriate place.

If anyone cares to see his review of this module, which he submitted without bothering to even try to use the module he criticized, have a look at the reviews for version 0.003.

=cut

1;
__END__
