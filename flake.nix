{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        coreutils ,
                        failure ,
                        findutils ,
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
                                                            runtimeInputs = [ coreutils findutils nix ( failure.implementation "d070b306" ) ] ;
                                                            text =
                                                                ''
                                                                    nix build ${ package } --out-link /scratch 2>&1
                                                                    PACKAGE="$( nix eval ${ package } --raw )" || failure
                                                                    find "$PACKAGE" -maxdepth 1 -mindepth 1 -name bin -exec ln --symbolic {} /mount \;
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
                                            expected-init ,
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
                                                                        runtimeInputs = [ ( failure "42ad3053" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed-init = implementation.init { resources = null ; self = null ; } ;
                                                                                in
                                                                                    ''
                                                                                        if [[ "${ expected-init }" != "${ observed-init }" ]]
                                                                                        then
                                                                                            failure "We expected the init to be ${ expected-init } but we observed ${ observed-init }" ;-
                                                                                        fi
                                                                                        if [[ '"[\"bin\"]"' != ${ builtins.toJSON implementation.targets } ]]
                                                                                        then
                                                                                            failure "We expected the targets to be bin"
                                                                                        fi
                                                                                        if [[ '"false"' != ${ builtins.toJSON implementation.transient } ]]
                                                                                        then
                                                                                            failure "We expected transient to be false"
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