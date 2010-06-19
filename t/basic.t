use strict;
use warnings;
use Test::More 'no_plan';

use File::Temp qw(tempdir);
use IO::File;
use Git::Wrapper;
use File::Spec;
use File::Path qw(mkpath);
use POSIX qw(strftime);
use Test::Deep;

my $dir = tempdir(CLEANUP => 1);

my $git = Git::Wrapper->new($dir);

$git->init;

mkpath(File::Spec->catfile($dir, 'foo'));

IO::File->new(">" . File::Spec->catfile($dir, qw(foo bar)))->print("hello\n");

is_deeply(
  [ $git->ls_files({ o => 1 }) ],
  [ 'foo/bar' ],
);

$git->add('.');
is_deeply(
  [ $git->ls_files ],
  [ 'foo/bar' ],
);

my $time = time;
$git->commit({ message => "FIRST" });

my @rev_list =
  $git->rev_list({ all => 1, pretty => 'oneline' });
is(@rev_list, 1);
like($rev_list[0], qr/^[a-f\d]{40} FIRST$/);

eval { $git->moo }; # very unlikely to exist, help.autocorrect guesses 'log'
if (my $e = $@) {   # autocorrect is off
  if ($git->version lt '1.6') {
    like($e, qr/which does not exist|Permission denied/);
  } elsif ($git->version lt '1.7') {
    like($e, qr/is not a git-command|Permission denied/);
  } else {
    like($e, qr/is not a git command|Permission denied/);
  }
}

my $date = strftime("%Y-%m-%d %H:%M:%S", localtime($time));
my @log = $git->log({ date => 'iso' });
is(@log, 1, 'one log entry');
my $log = $log[0];
is($log->id, (split /\s/, $rev_list[0])[0], 'id');
is($log->message, "FIRST\n", "message");
my $log_date = $log->date;
$log_date =~ s/ [+-]\d+$//;
is($log_date, $date, "date");
