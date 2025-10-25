{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        coreutils ,
                        failure ,
                        garbage-collection-root ,
                        nix ,
                        package ,
                        writeShellApplication
                    } :
                        let
                            implementation =
                                {
                                    init =
                                        { resources , self } :
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "init" ;
                                                            runtimeInputs = [ coreutils nix ( failure.implementation "d070b306" ) ] ;
                                                            text =
                                                                ''
                                                                    mkdir --parents ${ garbage-collection-root }
                                                                    FILE="$( mktemp --dry-run ${ garbage-collection-root }/XXXXXXXX )" || failure mktemp --dry-run ${ garbage-collection-root }
                                                                    nix build ${ package } --out-link "$FILE" 2>&1
                                                                    PACKAGE="$( nix eval ${ package } --raw )" || failure nix eval ${ package }
                                                                    ln --symbolic "$PACKAGE" /mount/derivation
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/init" ;
                                    targets = [ "bin" ] ;
                                    transient = false ;
                                } ;
                            in
                                {
                                    check =
                                        {
                                            mkDerivation
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase =
                                                        ''
                                                            execute-test "$out"
                                                        '' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test" ;
                                                                        runtimeInputs = [ nix ( failure "42ad3053" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed-init = implementation.init { resources = null ; self = null ; } ;
                                                                                in
                                                                                    ''
                                                                                        if nix eval ${ package } --raw
                                                                                        then
                                                                                            EXPECTED=true
                                                                                        else
                                                                                            EXPECTED=false
                                                                                        fi
                                                                                        if ${ implementation }
                                                                                        then
                                                                                            OBSERVED=true
                                                                                        else
                                                                                            OBSERVED=false
                                                                                        fi
                                                                                        if [[ "$EXPECTED" != "$OBSERVED" ]]
                                                                                        then
                                                                                            fail "We expected $EXPECTED but we observed $OBSERVED"
                                                                                        fi
                                                                                    '' ;
                                                                    }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}