use strict;
use warnings;
use feature 'say';

our $EXPORT_PATH = "$ENV{HOME}/.jrubincli/navigation";
our $MODE_FILE = "$EXPORT_PATH/mode";
system("mkdir -p $EXPORT_PATH");
# TODO check output
# TODO re-implement global-mode reading
#if [[ -s $EXPORT_PATH/mode ]]; then
#    global_mode=`cat $MODE_FILE`
#fi
#our $JRCLI_MODE="$global_mode"
our $JRCLI_MODE="gsg";
# TODO cache this between runs
our $JRUBIN_NAVIGATION_BASE;

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
    print "$JRUBIN_NAVIGATION_BASE/" . ($_[0] // '')
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
        #        export JRCLI_MODE="$mode"
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
    if ($JRCLI_MODE) {
        $debug .= " (mode: $JRCLI_MODE)"
    }
    debug "$debug:";

    my ($newproject, $newbase);

    for my $base_to_check (@bases_to_check) {

        if ( -d "$base_to_check/$project" ) {
            $newproject=$project
        }
        # Try with mode
        elsif ( -d "$base_to_check/$JRCLI_MODE-$project" ) {
            $newproject="$JRCLI_MODE-$project"
        }
        else {
            for my $path ( glob("$base_to_check/$JRCLI_MODE-$project*") ) {
                if ( -d $path ) {
                    if ( $newproject) {
                        my $is_perl_rx = qr/-(?:perl|carton)$/;
                        if ($path =~ $is_perl_rx) {
                            # Ignore the less-specific perl path
                        }
                        elsif ($newproject =~ $is_perl_rx) {
                            die "NOT IMPLEMENTED YET";
                            my $shouldquit=0;
                            #$newproject=$(basename $path);
                        }
                        else {
                            debug "  $project is not specific enough!";
                            return
                        }
                    }
                    # no newproject yet
                    else {
                        die "basename not set yet";
                        #$newproject=$(basename $path);
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
                                die "NOT IMPLEMENTED YET";;
                                my $shouldquit=0;
                                #$newproject=$(basename $path)
                            }
                            else {
                                debug "  $project is not specific enough!";
                                return
                            }
                        }
                        else {
                            die "basename not set yet";
                            #$newproject=$(basename $path)
                        }
                    }
                }
            }

            # Try mode without -
            if (!$newproject) {
                for my $path ( glob("$base_to_check/$JRCLI_MODE$project*") ) {
                    if ( -d $path ) { 
                        if ( $newproject ) {
                            my $is_perl_rx=/-(?:perl|carton)$/;
                            if ( $path =~ $is_perl_rx ) {
                                # Ignore the less-specific perl path
                            }
                            elsif ( $newproject =~ $is_perl_rx ) {
                                die "NOT IMPLEMENTED YET";
                                my $shouldquit=0;
                                #$newproject=$(basename $path)
                            }
                            else {
                                debug "  $project is not specific enough!";
                                return
                            }
                        }
                        else {
                            die "basename not set yet";
                            #$newproject=$(basename $path)
                        }
                    }
                }
            }

            # TODO modey stuff
            #if [[ -n $newproject ]]; then
            #    newbase=$base_to_check
            #    project=$newproject
            #    if [[ -z $mode ]]; then
            #        if [[ $project =~ ^gsgx ]]; then
            #            mode=gsgx
            #        elif [[ $project =~ ^gsg ]]; then
            #            mode=gsg
            #        fi
            #    fi

            #    if [[ -n $mode ]]; then
            #        export JRCLI_MODE="$mode"
            #        echo $mode > $MODE_FILE
            #    fi
            #    break
            #fi
        # try another base
        }

        last if $newproject;
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

    $JRUBIN_NAVIGATION_BASE = "$base/$project";
    _e()
}

# TODO don't call these
sub main_as_test {
    e(@ARGV);
}

main_as_test();
