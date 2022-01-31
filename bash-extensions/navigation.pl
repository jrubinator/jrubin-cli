use strict;
use warnings;
use feature 'say';

use File::Basename qw(basename);
use Getopt::Long qw(GetOptionsFromArray);
our $EXPORT_PATH = "$ENV{HOME}/.jrubincli/navigation";
our $PATCH_PATH  = "$EXPORT_PATH/patches";
our $PREFIX_FILE = "$EXPORT_PATH/current-prefix";
our $BASE_FILE = "$EXPORT_PATH/current-base";
for my $path ($EXPORT_PATH, $PATCH_PATH) {
    system("mkdir -p $path")
        and die "mkdir -p $path failed: $!";
}
for my $file ($PREFIX_FILE, $BASE_FILE) {
    system("touch $file")
        and die "touch $file failed: $!";
}

sub debug (@) {
    say STDERR @_;
}

sub e {
    if (@_ < 1) {
        return _e()
    }
    else {
        my $diving_board=`pwd`;
        my $new_base = change_base(@_);
        # TODO reimplement in perl
        # if we changed between the same git repo in different structures
        # try to stay at the same level
        #if [[ ! $diving_board =~ ^$HOME/$base/ ]]; then
        #    if [[ $diving_board =~ /$project/(.*)$ ]]; then
        #        cd ${BASH_REMATCH[1]}
        #    fi
        #fi
        apply_any_patches($new_base);
    }
}

sub _e {
    my $base = _read_file($BASE_FILE);
    my $dest = "$base/" .  ($_[0] // '');
    print $dest;
    return $dest;
}

sub ee {
    my $base = _read_file($BASE_FILE);
    my ($project) = $base =~ m{/([^/]+)$};
    my @pathparts = split '-' => $project;

    my $dest = "$base/" . join("/" => map { ucfirst } @pathparts);
    print $dest;
    return $dest;
}

sub apply_any_patches {
    my $where = shift;
    for my $patch (glob("$PATCH_PATH/*")) {
        my $failed = system("cd $where && git apply $patch && rm $patch");
        if ($failed) {
            debug "  Could not apply patch $patch";
            return;
        }
    }
}

sub change_base {
    my ($base, $global, $prefix, $file_to_move);
    GetOptionsFromArray(\@_,
        'global!'     => \$global,
        'base=s'      => \$base,
        'prefix=s'    => \$prefix,
        'file-path=s' => \$file_to_move,
    );
    my $project = shift;

    if (!$project) {
        debug "  No project specified";
        return
    }
    if (defined($base) && ! -d "$ENV{HOME}/$base") {
        debug "  Base $base doesn't seem to exist!";
        return;
    }
    $prefix ||= _read_file("$PREFIX_FILE");
    if ($file_to_move) {
        if (! -f "./$file_to_move" && ! -d "./$file_to_move") {
            debug "  $file_to_move doesn't seem to exist!";
            $file_to_move = undef;
        }
        else {
            # Replace / with _ in filename
            (my $patch_file= "$file_to_move.patch") =~ s{/}{_}g;
            my $failed = system("git diff $file_to_move > $PATCH_PATH/$patch_file");
            if ($failed) {
                debug "  Could not generate patch for $file_to_move";
                return;
            }
        }
    }

    my @bases_to_check;
    if ($base) {
        @bases_to_check = ("$ENV{HOME}/$base");
    }
    else {
        $base = _read_file($BASE_FILE) || 'default';
        @bases_to_check = (
            $base,
            (map { "$ENV{HOME}/$_" } qw(work alt)),
            split(' ' => `ls -d ~/go/src/*/*`),
        );
    }

    my $debug="Exporting $project ($base)";
    if ($prefix) {
        $debug .= " (prefix $prefix)"
    }
    debug "$debug:";

    my ($newproject, $newbase);

    for my $base_to_check (@bases_to_check) {

        if ( -d "$base_to_check/$project" ) {
            $newproject=$project;
        }
        # Try with prefix
        elsif ( -d "$base_to_check/$prefix-$project" ) {
            $newproject="$prefix-$project"
        }
        else {
            for my $path ( glob("$base_to_check/$prefix-$project*") ) {
                if ( -d $path ) {
                    if ( $newproject) {
                        my $is_perl_rx = qr/-(?:perl|carton)$/;
                        if ($path =~ $is_perl_rx) {
                            # Ignore the less-specific perl path
                        }
                        elsif ($newproject =~ $is_perl_rx) {
                            $newproject = basename($path);
                        }
                        else {
                            debug "  $project is not specific enough!";
                            return
                        }
                    }
                    # no newproject yet
                    else {
                        $newproject = basename($path);
                    }

                }
            }

            # Try no $prefix at all
            if (!$newproject) {
                for my $path ( glob("$base_to_check/$project*") ) {
                    if ( -d $path ) { 
                        if ( $newproject ) {
                            my $is_perl_rx = qr/-(?:perl|carton)$/;
                            if ( $path =~ $is_perl_rx ) {
                                # Ignore the less-specific perl path
                            }
                            # FIXME this is never set
                            elsif ( $newproject =~ $is_perl_rx ) {
                                $newproject = basename($path);
                            }
                            else {
                                debug "  $project is not specific enough!";
                                return
                            }
                        }
                        else {
                            $newproject = basename($path);
                        }
                    }
                }
            }

            # Try prefix without -
            if (!$newproject) {
                for my $path ( glob("$base_to_check/$prefix$project*") ) {
                    if ( -d $path ) { 
                        if ( $newproject ) {
                            my $is_perl_rx=/-(?:perl|carton)$/;
                            if ( $path =~ $is_perl_rx ) {
                                # Ignore the less-specific perl path
                            }
                            elsif ( $newproject =~ $is_perl_rx ) {
                                $newproject = basename($path);
                            }
                            else {
                                debug "  $project is not specific enough!";
                                return
                            }
                        }
                        else {
                            $newproject = basename($path);
                        }
                    }
                }
            }

            if ($newproject) {
                $project = $newproject
            }
        }

        if ($newproject) {
            $newbase = $base_to_check;

            if ($prefix) {
                undef $prefix unless $project =~ /^\Q$prefix/;
            }
            else {
                ($prefix) = $project =~ /^([^-]+)-/;
            }

            if ($prefix) {
                _write_file($PREFIX_FILE, $prefix);
            }

            last;
        }
    }

    if (!$newbase) {
        debug "  $project doesn't seem to exist";
        return;
    }

    $base = $newbase;
    _write_file($BASE_FILE, $base);

    if ($global) {
        # TODO cache global
        #echo $project > ~/jrubin/export/project
    }

    _write_file($BASE_FILE, "$base/$project");
    return _e()
}

sub _read_file {
    my $file = shift;

    open my $fh, '<', $file or die "Can't open $file $!";
    my $file_content = do { local $/; <$fh> };

    close $fh or warn "Can't close $file $!";
    return $file_content;
}

sub _write_file {
    my ($file, $contents) = @_;
    open (my $fh, '>', $file)
        or die "Can't open $file $!";
    print $fh $contents;
    close $fh
        or warn "Can't close $file $!";
}

# TODO don't call these
sub main_as_test {
    e(@ARGV);
}

main_as_test();
