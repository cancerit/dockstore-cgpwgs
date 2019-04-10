package PCAP::Threaded;

##########LICENCE##########
# PCAP - NGS reference implementations and helper code for the ICGC/TCGA Pan-Cancer Analysis Project
# Copyright (C) 2014-2018 ICGC PanCancer Project
# Copyright (C) 2018-2019 Cancer, Ageing and Somatic Mutation, Genome Research Limited
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not see:
#   http://www.gnu.org/licenses/gpl-2.0.html
##########LICENCE##########


use PCAP;

use strict;
use autodie qw(:all);
use English qw( -no_match_vars );
use warnings FATAL => 'all';
use Carp qw( croak );
use File::Spec;
use File::Path qw(make_path);
use Try::Tiny qw(try catch finally);
use Capture::Tiny qw(capture);
use Const::Fast qw(const);
use Scalar::Util qw(looks_like_number);
use Time::HiRes qw(usleep);

our $CAN_USE_THREADS = eval 'use threads; 1' || 0;

const my $SCRIPT_OCT_MODE => 0777;

our $OUT_ERR = 1;

sub new {
  my ($class, $max_threads) = @_;
  croak "Number of threads was NAN: $max_threads" if(defined $max_threads && !looks_like_number($max_threads));
  unless(defined $max_threads) {
    warn "Thread count not defined, defaulting to 1.\n";
    $max_threads = 1;
  }
  if($max_threads > 1 && $CAN_USE_THREADS == 0) {
    warn "Threading is not available perl component will run as a single process";
    $max_threads = 1;
  }

  my $self = {'threads' => $max_threads,
              'join_interval' => 1,};
  bless $self, $class;

  # get core count for optional auto-back off when oversubscribed
  $self->init_cores();

  return $self;
}

sub disable_out_err {
  $OUT_ERR = 0;
  return $OUT_ERR;
}

sub enable_out_err {
  $OUT_ERR = 1;
  return $OUT_ERR;
}

sub use_out_err {
  return $OUT_ERR;
}

sub init_cores {
  my $self = shift;
  if($ENV{PCAP_THREADED_LOADBACKOFF}) {
    my ($cpus, $se, $ex) = capture { system('grep -c ^processor /proc/cpuinfo'); };
    chomp $cpus;
    $self->{'system_cpus'} = $cpus;
  }
  return 1;
}

sub need_backoff {
  my $self = shift;
  my $ret = 0;
  # don't want to change normal behaviour
  if($ENV{PCAP_THREADED_LOADBACKOFF}) {
    my($uptime, $se, $ex) = capture { system('uptime'); };
    chomp $uptime;
    # probably only need 1-min but grab them all
    my ($one_min, $five_min, $fifteen_min) = $uptime =~ m/load average: ([[:digit:]]+\.[[:digit:]]+), ([[:digit:]]+\.[[:digit:]]+), ([[:digit:]]+\.[[:digit:]]+)$/;
    $ret = 1 if($one_min > $self->{'system_cpus'});
  }
  return $ret;
}

sub add_function {
  my ($self, $function_name, $function_ref, $divisor) = @_;
  croak "Function $function_name has already been defined.\n" if(exists $self->{'functions'}->{$function_name}->{'code'});
  my $ref_type = ref $function_ref;
  $ref_type ||= 'not a reference';
  croak "Second argument to add_function should be a code reference, I got '$ref_type'.\n" unless('CODE' eq ref $function_ref);

  $self->{'functions'}->{$function_name}->{'code'} = $function_ref;
  $self->{'functions'}->{$function_name}->{'threads'} = $self->_suitable_threads($divisor);

  return 1;
}

sub thread_join_interval {
  my ($self, $sec) = @_;
  if(defined $sec) {
    croak 'join_interval must be an integer' if($sec !~ m/^[[:digit:]]+$/);
    croak 'join_interval must be 1 or more' if($sec < 1);
    $self->{'join_interval'} = $sec;
  }
  $self->{'join_interval'};
}

sub run {
  my ($self, $iterations, $function_name, @params) = @_;
  croak 'Iterations must be defined' unless(defined $iterations);
  croak "Iterations must be a positive integer: $iterations" if($iterations !~ m/^[[:digit:]]+$/ || $iterations == 0);
  croak 'Function_name must be defined' unless(defined $function_name);
  croak "Unable to find '$function_name', please check your declaration of add_function()\n."
    unless(exists $self->{'functions'}->{$function_name}->{'code'});

  my $function_ref = $self->{'functions'}->{$function_name}->{'code'};
  my $thread_count = $self->{'functions'}->{$function_name}->{'threads'};

  my $start_interval = 6; # initial scaling
  if($self->{'threads'} >= 8) {
    # when core count is higher spread the scaling up over 2 minutes
    $start_interval = int 120 / $self->{'threads'};
    $start_interval = 6 if($start_interval < 6);
  }

  # uncoverable branch true
  if($thread_count > 1 && $CAN_USE_THREADS) {
    # reserve 0 for when people want to use 'success_exists/touch_success' for non-threaded steps
    # makes it easy to see in progress area which steps are threaded
    my $index = 1;
    while($index <= $iterations) {
      while(threads->list(threads::all()) < $thread_count && $index <= $iterations) {
        while($self->need_backoff) {
          warn "Excessive load average, take a break... have a Kit-Kat!\n";
          sleep 30;
        }
        threads->create($function_ref, $index++, @params);
        last if($index > $iterations);
        usleep($start_interval * 1_000_000);
      }
      $start_interval = 0.1; # once the initial scale up is complete start interval can be tiny.
      sleep $self->thread_join_interval while(threads->list(threads::joinable()) == 0);
      for my $thr(threads->list(threads::joinable())) {
        $thr->join;
        if(my $err = $thr->error) { die "Thread error: $err\n"; }
      }
    }
    # last gasp for any remaining threads
    sleep $self->thread_join_interval while(threads->list(threads::running()) > 0);
    for my $thr(threads->list(threads::joinable())) {
      $thr->join;
      if(my $err = $thr->error) { die "Thread error: $err\n"; }
    }
  }
  else {
    for my $index(1..$iterations) {
      &{$function_ref}($index, @params);
    }
  }
  return 1;
}

sub _suitable_threads {
  my ($self, $divisor) = @_;
  my $suitable_threads = $self->{'threads'};
  if(defined $divisor) {
    croak "Thread divisior must be a positive integer: $divisor\n." if($divisor !~ m/^[[:digit:]]+$/xms || $divisor == 0);
    $suitable_threads = int ($suitable_threads / $divisor);
    $suitable_threads++ if($suitable_threads == 0);
  }
  return $suitable_threads;
}

sub success_exists {
  my ($tmp, @indexes) = @_;
  my ($legacy_type) = (caller(1))[3];
  my $new_type = $legacy_type;
  $new_type =~ s/::/_/g;

  my $suffix = join '.', @indexes;
  for my $type($new_type, $legacy_type) { # we should test the new file name style first
    my $file = $type.'.'.$suffix;
    my $path = File::Spec->catfile($tmp, $file);
    if(-e $path) {
      warn "Skipping $file as previously successful\n";
      return 1;
    }
  }
  return 0;
}

sub touch_success {
  my ($tmp, @indexes) = @_;
  my ($type) = (caller(1))[3];
  $type =~ s/::/_/g;
  make_path($tmp) unless(-d $tmp);
  my $file = join '.', $type, @indexes;
  my $path = File::Spec->catfile($tmp, $file);
  open my $TOUCH, '>', $path;
  close $TOUCH;
  return 1;
}

sub _legacy_touch_success {
  my ($tmp, @indexes) = @_;
  my ($type) = (caller(1))[3];
  make_path($tmp) unless(-d $tmp);
  my $file = join '.', $type, @indexes;
  my $path = File::Spec->catfile($tmp, $file);
  open my $TOUCH, '>', $path;
  close $TOUCH;
  return 1;
}

sub external_process_handler {
  my ($tmp, $command_in, @indexes) = @_;

  my @commands;
  if(ref $command_in eq 'ARRAY') {
    @commands = @{$command_in}
  }
  else {
    @commands = ($command_in);
  }

  if(&use_out_err == 0) {
    # these may be marshalled to different files so output both
    try {
      for my $c(@commands) {
        warn "\nErrors from command: $c\n\n";
        print "\nOutput from command: $c\n\n";
        system($c);
      }
    }
    catch { die $_; };
  }
  else {
    my $caller = (caller(1))[3];
    $caller =~ s/::/_/g;
    my $suffix = join q{.}, @indexes;

    my $script = _create_script(\@commands, File::Spec->catfile($tmp, "$caller.$suffix"));

    my $out = File::Spec->catfile($tmp, "$caller.$suffix.out");
    my $err = File::Spec->catfile($tmp, "$caller.$suffix.err");

    try {
      system("/usr/bin/time bash $script 1> $out 2> $err");
    }
    catch {
      warn "\nGeneral output can be found in this file: $out\n";
      warn "Errors can be found in this file: $err\n\n";
      die "Wrapper script message:\n".$_;
    };

    unlink $script; # only leave scripts if we fail
    if($ENV{PCAP_THREADED_REM_LOGS}) {
      unlink $err;
      unlink $out;
    }
  }

  return 1;
}

sub _create_script {
  my ($commands, $stub) = @_;

  my $script = "$stub.sh";

  if($ENV{PCAP_THREADED_NO_SCRIPT} && -e $script) {
    die "ERROR: Script already present, delete to proceed: $script";
  }

  open my $SH, '>', $script or die "Failed to create $script";
  print $SH qq{#!/bin/bash\nset -eux\n} or die "Write to $script failed";
  print $SH join qq{\n}, @{$commands}, q{} or die "Write to $script failed";
  close $SH;

  my $microsec = 100_000;
  _file_complete($script, $microsec);
  return $script;
}

sub _file_complete {
  my ($script, $microsec) = @_;
  usleep($microsec);
  my $tries = 0;
  while(! -e $script) {
    $tries++;
    croak "Failed to find script after 30 attempts ($microsec us delays): $script" if($tries >= 30);
    usleep($microsec);
  }
  $tries = 0;
  while(1) {
    $tries++;
    croak "Failed to confirm write complete after 30 attempts ($microsec us delays): $script" if($tries >= 30);
    my ($stdout, $stderr, $exit) = capture { system([0,1], 'fuser', $script); };
    if($exit > 1) {
      croak sprintf "ERROR: fuser output\n\tSTDOUT: %s\n\tSTDERR: %s\n\tEXIT: %d\n", $stdout, $stderr, $exit;
    }
    printf STDERR "OUT : %s\nERR : %s\nEXIT: %s\n", $stdout,$stderr,$exit if($exit == 0);
    last if($exit == 1);
    usleep($microsec);
  }
  return 1;
}

1;

__END__

=head1 NAME

PCAP::Threaded - Run threaded processing easily.

=head2 Constructor

=over 4

=item PCAP::Threaded->new(max_threads)

Generate a threaded processing object with the defined number of threads.

=back

=head2 Methods

=over 4

=item add_function

Register a named coderef to be run using threads.

  $threads->add_function($function_name, $coderef [, $divisor]);

  function_name - Text to address function by in L<run()|PCAP::Threaded/run>.
  coderef       - Reference to subroutine.
  divisor       - See L<_suitable_threads()|PCAP::Threaded/_suitable_threads>.

=item run

Run the named function for the stated number of iterations.

NOTE: If your process needs to honor selected index processing this needs to be handled in the
callback registered in add_function.

  $threads->run($iterations, $function_name, @params);

  iterations    - Number of times the function should be started iteration
                  number (origin 1) is passed as first argument to the code-ref
                  defined in L<add_function()|PCAP::Threaded/add_function>.
  function_name - Name of function as defined in L<add_function()|PCAP::Threaded/add_function>.
  @params       - Any additional params for the coderef.

=back

=head2 Utility Methods

These are non-object methods which are useful to related code

=head3 Configuration

=over 4

=item use_out_err

Determines if stdout/stderr are redirected to file, by default 1/true.

=item disable_out_err

Prevent calls to external_process_handler from redirecting stdout/stderr to files.

=item enable_out_err

Enable redirect of stdout/stderr to files when calling external_process_handler.

=item thread_join_interval

Set/get the number of seconds to wait between thread joins.  Default 1.

=back

=head3 Resume Helpers

These are useful methods to help you program resume from the last successfully completed step.

It is recommended that you use these in any callbacks used in the
L<run()|PCAP::Threaded/run> function to prevent unnecessary processing after restarting
a job.

These can also be used for other processes in your program flow that aren't using threads.  Where
these don't require an incrementing index value please use '0' (zero);

=over 4

=item success_exists

B<Before> compute step add this code:

  return if PCAP::Threaded::success_exists($tmpdir, $index[, $index_2...]);

Requires implementation of L<touch_success()|PCAP::Threaded/touch_success>.

($index_2... may be useful for some other implementation, see L<bwa_aln()|PCAP::Bwa/bwa_aln>).

=item touch_success

B<After> compute step add this code:

  return if PCAP::Threaded::touch_success($tmpdir, $index[, $index_2...]);

Requires implementation of L<success_exists()|PCAP::Threaded/touch_success>.

($index_2... may be useful for some other implementation, see L<bwa_aln()|PCAP::Bwa/bwa_aln>).

=item external_process_handler

  PCAP::Threaded::external_process_handler($logdir, $commands, $index[, $index_2...]);

  @params logdir   - Path to pre-existing log directory
  @params commands - Scalar command or arr-ref of commands
  @params index    - Which index this is, specifically for log/err files.

Wraps up command with stdout and stderr catchalls to keep the output of each threaded process
separated from the script itself.  Added to simplify interpretation of any issues that may occur.

If you don't want to capture stdout/stderr see <disable_out_err>.

($index_2... may be useful for some other implementation, see L<bwa_aln()|PCAP::Bwa/bwa_aln>).

=back

=head2 Internal functions

=over 4

=item _suitable_threads

  $self->_suitable_threads($divisor);

If the code-ref to be executed uses multiple threads (or piped processes) the total number of
parallel jobs will be divided by this number to prevent over subscription of resources.  Take this
simple example:

  grep -wF 'wibble' | cut -f 5 | sort | uniq -c

This 'pipeline' can theoretically use 4 CPU's at 100% each.  When executing multiple parallel
executions of this the total number of threads defined on the command line is divided by the
provided value:

  max_parallel = int(total_threads / divisor);
  max_parallel++ if(max_parallel == 0);

If total_threads is < divisor a single process will run, any prevention of oversubscription then
falls to the OS and any CPU affinity settings.

=back
