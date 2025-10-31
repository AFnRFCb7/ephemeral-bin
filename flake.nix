{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        coreutils ,
                        garbage-collection-root ,
                        nix ,
                        writeShellApplication
                    } :
                        let
                            implementation =
                                {
                                    package
                                } :
                                    {
                                        init =
                                            { resources , self } :
                                                let
                                                    application =
                                                        writeShellApplication
                                                            {
                                                                name = "init" ;
                                                                runtimeInputs = [ coreutils nix ] ;
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
                                            expected ,
                                            failure ,
                                            mkDerivation ,
                                            package ,
                                            resources ? null ,
                                            self ? null
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase = ''execute-test "$out"'' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test" ;
                                                                        runtimeInputs = [ coreutils failure ] ;
                                                                        text =
                                                                            let
                                                                                init = instance.init { resources = resources ; self = self ; } ;
                                                                                instance = implementation { package = package ; } ;
                                                                                in
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        ${ if [ "init" "targets" ] != builtins.attrNames instance then ''failure ephemeral names "We expected the names to be init targets but we observed" "${ builtins.toJSON ( builtins.attrNames instance ) }"'' else "#" }
                                                                                        ${ if expected != builtins.toString init then ''failure ephemeral init "We expected the init to be ${ expected } but we observed ${ builtins.toString init }"'' else "#" }
                                                                                        ${ if [ "ephemeral" ] != instance.targets then ''failure ephemeral targets "We expected the targets to be ephemeral but we observed ${ builtins.toJSON instance.targets }"'' else "#" }
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