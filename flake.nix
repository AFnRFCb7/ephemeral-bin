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
                                                                    ln --symbolic "$PACKAGE" /mount/ephemeral
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/init" ;
                                    targets = [ "ephemeral" ] ;
                                } ;
                            in
                                {
                                    check =
                                        {
                                            expected-init ,
                                            mkDerivation ,
                                            resources ? null ,
                                            self ? null
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase =
                                                        ''
                                                            execute-test-init "$out"
                                                            execute-test-targets "$out"
                                                            execute-test-names "$out"
                                                        '' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-init" ;
                                                                        runtimeInputs = [ coreutils ( failure.implementation "e75eb2bc" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed = implementation.init { resources = resources ; self = self ; } ;
                                                                                in
                                                                                    if expected-init == observed then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                            failure We expected ${ builtins.toString expected-init } but we observed ${ builtins.toString observed }
                                                                                        '' ;
                                                                    }
                                                            )
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-targets" ;
                                                                        runtimeInputs = [ coreutils ( failure.implementation "1cbc4bb0" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed-targets = implementation.targets ;
                                                                                in
                                                                                    if [ "derivation" ] == observed-targets then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                            failure "We expected the targets to be [ derivation ] but we observed ${ builtins.toJSON observed-targets }"
                                                                                        '' ;
                                                                    }
                                                            )
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test-names" ;
                                                                        runtimeInputs = [ coreutils ( failure.implementation "1cbc4bb0" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed-names = builtins.attrNames implementation ;
                                                                                in
                                                                                    if [ "init" "targets" ] == observed-names then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                            failure 'We expected the targets to be [ init targets ] but we observed ${ builtins.toJSON observed-names }'
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