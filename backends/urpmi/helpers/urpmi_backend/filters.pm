#
# Copyright (C) 2008 Aurelien Lefebvre <alkh@mandriva.org>
#
# Licensed under the GNU General Public License Version 2
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#

package urpmi_backend::filters;

use MDK::Common;
use perl_packagekit::enums;
use urpmi_backend::tools;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(filter);

my @gui_pkgs = map { chomp; $_ } cat_('/usr/share/rpmdrake/gui.lst');

sub filter {
  my ($urpm, $pkg, $filters, $enabled_filters) = @_;

  my %e_filters = %$enabled_filters;

  foreach my $filter (@$filters) {
    if ($filter eq FILTER_INSTALLED || $filter eq FILTER_NOT_INSTALLED) {
      if ($e_filters{FILTER_INSTALLED}) {
        return 0 if !filter_installed($pkg, $filter);
      }
    }
    elsif ($filter eq FILTER_DEVELOPMENT || $filter eq FILTER_NOT_DEVELOPMENT) {
      if ($e_filters{FILTER_DEVELOPMENT}) {
        return 0 if !filter_devel($pkg, $filter);
      }
    }
    elsif ($filter eq FILTER_GUI || $filter eq FILTER_NOT_GUI) {
      if ($e_filters{FILTER_GUI}) {
        return 0 if !filter_gui($pkg, $filter);
      }
    }
    elsif ($filter eq FILTER_SUPPORTED || $filter eq FILTER_NOT_SUPPORTED) {
      if ($e_filters{FILTER_SUPPORTED}) {
        return 0 if !filter_supported($urpm, $pkg, $filter);
      }
    }
    elsif ($filter eq FILTER_FREE || $filter eq FILTER_NOT_FREE) {
      if ($e_filters{FILTER_FREE}) {
        return 0 if !filter_free($urpm, $pkg, $filter);
      }
    }
  }
  return 1;
}

sub filter_installed {
  my ($pkg, $filter) = @_;
  my $installed = is_package_installed($pkg) ? 1 : 0;
  return 1 if $filter eq FILTER_INSTALLED && $installed;
  return 1 if $filter eq FILTER_NOT_INSTALLED && !$installed;
  return 0;
}

sub filter_devel {
  my ($pkg, $filter) = @_;
  my $pkgname = $pkg->name;
  my $devel = $pkgname =~ /-devel$/;

  return 1 if $filter eq FILTER_DEVELOPMENT && $devel;
  return 1 if $filter eq FILTER_NOT_DEVELOPMENT && !$devel;
  return 0;
}

sub filter_gui {
  my ($pkg, $filter) = @_;
  my $pkgname = $pkg->name;
  my $gui = member($pkgname, @gui_pkgs);

  if ($filter eq FILTER_NOT_GUI && !$gui) {
    return 1;
  }
  if ($filter eq FILTER_GUI && $gui) {
    return 1;
  }
  return 0;
}

sub filter_supported {
  my ($urpm, $pkg, $filter) = @_;
  my $media = pkg2medium($pkg, $urpm);
  return 0 unless defined($media);

  my $medianame = $media->{name};
  # FIXME: matching against media name is certainly not optimal,
  #        better heuristics needed...
  #        could be blacklisting 'contrib' or better check for 'media_type=official'
  my $supported = $medianame =~ /^(?:core|main)/i;

  if ($filter eq FILTER_SUPPORTED && $supported) {
    return 1;
  }
  if ($filter eq FILTER_NOT_SUPPORTED && !$supported) {
    return 1;
  }
  return 0;
}

sub filter_free {
  my ($urpm, $pkg, $filter) = @_;
  my $media = pkg2medium($pkg, $urpm);
  return 0 unless defined($media);

  my $medianame = $media->{name};
  # FIXME: matching against media name is certainly not optimal,
  #        better heuristics needed...
  my $free = $medianame !~ /non-free/i;

  if ($filter eq FILTER_FREE && $free) {
    return 1;
  }
  if ($filter eq FILTER_NOT_FREE && !$free) {
    return 1;
  }
  return 0;
}

1;
