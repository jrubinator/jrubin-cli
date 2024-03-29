# TODO document!
use strict;
use warnings;
use feature 'say';

use File::Basename qw(basename);
use Getopt::Long qw(GetOptionsFromArray);
our $EXPORT_PATH = "$ENV{HOME}/.jrubincli/navigation";
our $PATCH_PATH  = "$EXPORT_PATH/patches";
our $PREFIX_FILE = "$EXPORT_PATH/current-prefix";
our $PROJECT_FILE = "$EXPORT_PATH/current-project";
for my $path ($EXPORT_PATH, $PATCH_PATH) {
    system("mkdir -p $path")
        and die "mkdir -p $path failed: $!";
}
for my $file ($PREFIX_FILE, $PROJECT_FILE) {
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
        my $new_base = change_base(@_);
        apply_any_patches($new_base);
    }
}

sub _e {
    # If we ever try to use _get_current_project_path here
    # we'll need to uncache before calling it
    my $dest = _read_file($PROJECT_FILE);
    print $dest;
    return $dest;
}

sub ee {
    # This could use _get_current_project_path
    # and I don't *think* it would introduce any caching bugs
    my $project_path = _read_file($PROJECT_FILE);
    my ($project) = $project_path =~ m{/([^/]+)$};
    my @pathparts = split '-' => $project;

    my $dest = "$project_path/" . join("/" => map { ucfirst } @pathparts);
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
    my ($base, $prefix, $file_to_move);
    GetOptionsFromArray(\@_,
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
        $base = get_current_base();
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
            my @paths = glob("$base_to_check/$prefix-$project*");
            for my $path ( @paths ) {
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
                            debug "  $project is not specific enough. Did you mean:\n"
                                . join("\n" => @paths);
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
                my @paths = glob("$base_to_check/$project*");
                for my $path ( @paths ) {
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
                                debug "  $project is not specific enough. Did you mean:\n"
                                    . join("\n" => @paths);
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
                my @paths = glob("$base_to_check/$prefix$project*");
                for my $path ( @paths ) {
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
                                debug "  $project is not specific enough. Did you mean:\n"
                                    . join("\n" => @paths);
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
                undef $prefix unless $newproject =~ /^\Q$prefix/;
            }
            else {
                ($prefix) = $newproject =~ /^([^-]+)-/;
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
    _write_file($PROJECT_FILE, "$base/$newproject");
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

sub get_current_project {
    my ($project) = _get_current_project_path() =~ m{/([^/]+)$};
    return $project;
}

sub get_current_base {
    my $full_path = _get_current_project_path();
    $full_path =~ s{/([^/]+)$}{};
    return $full_path;
}

my $_current_project_path;
sub _get_current_project_path {
    if (!$_current_project_path) {
        $_current_project_path = _read_file($PROJECT_FILE);
    }
    return $_current_project_path;
}

e(@ARGV);
