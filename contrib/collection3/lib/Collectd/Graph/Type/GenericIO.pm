package Collectd::Graph::Type::GenericIO;

use strict;
use warnings;
use base ('Collectd::Graph::Type');

use Carp ('confess');

use Collectd::Graph::Common (qw($ColorCanvas ident_to_filename get_faded_color));

return (1);

sub getRRDArgs
{
  my $obj = shift;
  my $index = shift;

  my $ident = $obj->{'files'}[$index] || confess ("Unknown index $index");
  my $filename = ident_to_filename ($ident);

  my $rrd_opts = $obj->{'rrd_opts'} || [];
  my $rrd_title = $obj->getTitle ($ident);
  my $format = $obj->{'rrd_format'} || '%5.1lf%s';

  my $ds_list = $obj->getDataSources ();
  my $ds_names = $obj->{'ds_names'};
  if (!$ds_names)
  {
    $ds_names = {};
  }

  my $colors = $obj->{'rrd_colors'} || {};
  my @ret = ('-t', $rrd_title, @$rrd_opts);

  if (defined $obj->{'rrd_vertical'})
  {
    push (@ret, '-v', $obj->{'rrd_vertical'});
  }

  if (@$ds_list != 2)
  {
    my $num = 0 + @$ds_list;
    confess ("Expected two data sources, but there is/are $num");
  }

  my $rx_ds = $ds_list->[0];
  my $tx_ds = $ds_list->[1];

  my $rx_ds_name = $ds_names->{$rx_ds} || $rx_ds;
  my $tx_ds_name = $ds_names->{$tx_ds} || $tx_ds;

  my $rx_color_fg = $colors->{$rx_ds} || '0000ff';
  my $tx_color_fg = $colors->{$tx_ds} || '00b000';

  my $rx_color_bg = get_faded_color ($rx_color_fg);
  my $tx_color_bg = get_faded_color ($tx_color_fg);
  my $overlap_color = get_faded_color ($rx_color_bg, background => $tx_color_bg);

  $filename =~ s#:#\\:#g;
  $rx_ds =~ s#:#\\:#g;
  $tx_ds =~ s#:#\\:#g;
  $rx_ds_name =~ s#:#\\:#g;
  $tx_ds_name =~ s#:#\\:#g;

  if ($obj->{'scale'})
  {
    my $factor = $obj->{'scale'};

    push (@ret,
	"DEF:min_rx_raw=${filename}:${rx_ds}:MIN",
	"DEF:avg_rx_raw=${filename}:${rx_ds}:AVERAGE",
	"DEF:max_rx_raw=${filename}:${rx_ds}:MAX",
	"DEF:min_tx_raw=${filename}:${tx_ds}:MIN",
	"DEF:avg_tx_raw=${filename}:${tx_ds}:AVERAGE",
	"DEF:max_tx_raw=${filename}:${tx_ds}:MAX",
	"CDEF:min_rx=min_rx_raw,${factor},*",
	"CDEF:avg_rx=avg_rx_raw,${factor},*",
	"CDEF:max_rx=max_rx_raw,${factor},*",
	"CDEF:min_tx=min_tx_raw,${factor},*",
	"CDEF:avg_tx=avg_tx_raw,${factor},*",
	"CDEF:max_tx=max_tx_raw,${factor},*");
  }
  else # (!$obj->{'scale'})
  {
    push (@ret,
	"DEF:min_rx=${filename}:${rx_ds}:MIN",
	"DEF:avg_rx=${filename}:${rx_ds}:AVERAGE",
	"DEF:max_rx=${filename}:${rx_ds}:MAX",
	"DEF:min_tx=${filename}:${tx_ds}:MIN",
	"DEF:avg_tx=${filename}:${tx_ds}:AVERAGE",
	"DEF:max_tx=${filename}:${tx_ds}:MAX");
  }

  push (@ret,
      "CDEF:overlap=avg_rx,avg_tx,LT,avg_rx,avg_tx,IF",
      "AREA:avg_rx#${rx_color_bg}",
      "AREA:avg_tx#${tx_color_bg}",
      "AREA:overlap#${overlap_color}",
      "LINE1:avg_rx#${rx_color_fg}:${rx_ds_name}",
      "GPRINT:min_rx:MIN:${format} Min,",
      "GPRINT:avg_rx:AVERAGE:${format} Avg,",
      "GPRINT:max_rx:MAX:${format} Max,",
      "GPRINT:avg_rx:LAST:${format} Last\\l",
      "LINE1:avg_tx#${tx_color_fg}:${tx_ds_name}",
      "GPRINT:min_tx:MIN:${format} Min,",
      "GPRINT:avg_tx:AVERAGE:${format} Avg,",
      "GPRINT:max_tx:MAX:${format} Max,",
      "GPRINT:avg_tx:LAST:${format} Last\\l");

  return (\@ret);
} # getRRDArgs

# vim: set shiftwidth=2 softtabstop=2 tabstop=8 :
