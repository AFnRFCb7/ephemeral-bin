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
                                    targets = [ "derivation" ] ;
                                } ;
                            in
                                {
                                    check =
                                        {
                                            expected ,
                                            mkDerivation ,
                                            resources ? null ,
                                            self ? null
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
                                                                        runtimeInputs = [ failure ] ;
                                                                        text =
                                                                            let
                                                                                observed = implementation { resources = resources ; self = self ; } ;
                                                                                in
                                                                                    if expected == observed then
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            failure wtf
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