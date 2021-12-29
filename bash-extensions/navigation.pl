use strict;
use warnings;
use feature 'say';

use File::Basename qw(basename);
our $EXPORT_PATH = "$ENV{HOME}/.jrubincli/navigation";
our $MODE_FILE = "$EXPORT_PATH/mode";
system("mkdir -p $EXPORT_PATH")
    and die "mkdir -p $EXPORT_PATH failed: $!";
my $PROJECT_PREFIX  = _read_file("$EXPORT_PATH/current-prefix");
my $NAVIGATION_BASE = "$EXPORT_PATH/current-base";

sub debug (@) {
    say STDERR @_;
}

sub e {
    if (@_ < 1) {
        return _e()
    }
    else {
        my $diving_board=`pwd`;
        change_base(@_);
        # TODO reimplement in perl
        # if we changed between the same git repo in different structures
        # try to stay at the same level
        #if [[ ! $diving_board =~ ^$HOME/$base/ ]]; then
        #    if [[ $diving_board =~ /$project/(.*)$ ]]; then
        #        cd ${BASH_REMATCH[1]}
        #    fi
        #fi
        apply_any_patches();
    }
}

sub _e {
    my $base = _read_file($NAVIGATION_BASE);
    print "$base/" .  ($_[0] // '');
}

sub ee {
    my $base = _read_file($NAVIGATION_BASE);
    my ($project) = $base =~ m{/([^/]+)$};
    my @pathparts = split '-' => $project;

    my $dest = "$base/" . join("/" => map { ucfirst } @pathparts);
    print $dest;
    return $dest;
}

sub apply_any_patches {
    # TODO re-implement in perl
    #shopt -s nullglob
    #for patch in ~/jrubin/export/patches/*; do
    #    git apply $patch && rm $patch
    #done
    #shopt -u nullglob
}

sub change_base {
    my $project = shift;
    my ($base, $global, $mode);

    while (@_) {
        my $key = shift;

        # TODO re-implement with Getopt
        #case $key in
        #    -g|--global)
        #        global=1
        #    ;;
        #    -b|--base)
        #        base=~/$1
        #        shift
        #        if [[ ${#base} < 1 ]]; then
        #            >&2 echo "  You must specify a base!"
        #            return
        #        elif [[ ! -d $base ]]; then
        #            >&2 echo "  $base doesn't seem to exist!"
        #            return
        #        fi

        #        export EXP_BASE="$base"
        #    ;;
        #    -m|--mode)
        #        mode="$1"
        #        shift
        #        export PROJECT_PREFIX="$mode"
        #        echo $mode > ~/jrubin/export/mode
        #    ;;
        #    -f|--file|--file-path)
        #        file_to_move="$1"
        #        if [[ ! -f ./$file_to_move && ! -d ./$file_to_move ]]; then
        #            >&2 echo "  $file_to_move doesn't seem to exist!"
        #            unset $file_to_move
        #        else
        #            patch_dir=~/jrubin/export/patches
        #            # Replace / with _ in filename
        #            patch_file="${file_to_move//\//_}.patch"
        #            mkdir -p $patch_dir
        #            git diff $file_to_move > $patch_dir/$patch_file
        #        fi
        #    ;;
        #esac
    }

    my @bases_to_check;
    if ($base) {
        @bases_to_check = ($base);
    }
    else {
        # TODO cache base
        #base="$EXP_BASE"
        #if [[ ${#base} < 1 ]]; then
        #    base='work'
        #fi
        $base = 'work';
        @bases_to_check = (
            $base,
            (map { "$ENV{HOME}/$_" } qw(work alt)),
            split(' ' => `ls -d ~/go/src/*/*`),
        );
    }

    my $debug="Exporting $project ($base)";
    if ($PROJECT_PREFIX) {
        $debug .= " (prefix $PROJECT_PREFIX)"
    }
    debug "$debug:";

    my ($newproject, $newbase);

    for my $base_to_check (@bases_to_check) {

        if ( -d "$base_to_check/$project" ) {
            $newproject=$project
        }
        # Try with mode
        elsif ( -d "$base_to_check/$PROJECT_PREFIX-$project" ) {
            $newproject="$PROJECT_PREFIX-$project"
        }
        else {
            for my $path ( glob("$base_to_check/$PROJECT_PREFIX-$project*") ) {
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

            # Try no $mode at all
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

            # Try mode without -
            if (!$newproject) {
                for my $path ( glob("$base_to_check/$PROJECT_PREFIX$project*") ) {
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
            # TODO modey stuff
            #if [[ -n $newproject ]]; then
            #    newbase=$base_to_check
            #    if [[ -z $mode ]]; then
            #        if [[ $project =~ ^gsgx ]]; then
            #            mode=gsgx
            #        elif [[ $project =~ ^gsg ]]; then
            #            mode=gsg
            #        fi
            #    fi

            #    if [[ -n $mode ]]; then
            #        export PROJECT_PREFIX="$mode"
            #        echo $mode > $MODE_FILE
            #    fi
            #    break
            #fi
        # try another base
        }

        if ($newproject) {
            $base = $base_to_check;
            last;
        }
    }

    #if [[ -z $newbase ]]; then
    #    >&2 echo "  $project doesn't seem to exist"
    #    return
    #else
    #    base=$newbase
    #    export EXP_BASE="$newbase"
    #fi

    if ($global) {
        # TODO cache global
        #echo $project > ~/jrubin/export/project
    }

    open (my $fh, '>', $NAVIGATION_BASE)
        or die "Can't open $NAVIGATION_BASE: $!";
    print $fh "$base/$project";
    close $fh
        or warn "Can't close $NAVIGATION_BASE: $!";
    _e()
}

sub _read_file {
    my $file = shift;

    open my $fh, '<', $file or die "Can't open $file $!";
    my $file_content = do { local $/; <$fh> };

    close $fh or warn "Can't close $file $!";
    return $file_content;
}

# TODO don't call these
sub main_as_test {
    e(@ARGV);
}

main_as_test();
